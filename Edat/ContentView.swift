//
//  ContentView.swift
//  Edat
//
//  Created by Alice Grace on 5/3/24.
//

import SwiftUI

import AVFoundation

import DaCo
import zer0_ios

private let defaultServer: Server = .init(
  protocolType: EDAT_SERVER_PROTOCOL,
  host: EDAT_SERVER_HOST,
  port: EDAT_SERVER_PORT,
  endPoint: EDAT_SERVER_ENDPOINT_DATA,
  headers: [.init(value: EDAT_API_SECRET, field: EDAT_API_SECRET_FIELD)]
)

private var engine: AVAudioEngine?
private var inputFormat: AVAudioFormat?
private var daco: DaCo?
private var noteTable: [[Float]] = createNoteTable(frequencyRoot: .magic)
private var noteTableSize: Int = noteTable.reduce(noteTable.count) { prev, next in prev + next.count }

struct ContentView: View {
  @State private var enableNetworking: Bool = getUserDefault(key: "EnableNetworking", defaultValue: true)

  @State private var volume: Float = getUserDefault(key: "Volume", defaultValue: 100.0)

  @State private var bpm: Float = getUserDefault(key: "BPM", defaultValue: 90.0)
  @State private var bpmSync: Bool = getUserDefault(key: "BPMSync", defaultValue: true)
  @State private var beatSignal: Bool = false

  @State private var frequencyHistory: [Float] = [0.0]

  @State private var selectedScaleKey: Note = getInitialSelectedScaleKey()
  @State private var selectedScale: Scale = getInitialSelectedScale()
  @State private var selectedScaleInKey: Scale = getScaleInKey(scale: getInitialSelectedScale(), key: getInitialSelectedScaleKey())

  @State private var synths: [Synth] = []
  @State private var synthPlayModes: [UUID: PlayMode] = [:]

  @State private var playStarting: Bool = false
  @State private var playing: Bool = false
  @State private var fullyStopped: Bool = true

  @State private var sequences: [UUID: Sequence] = [:]

  var body: some View {
    NavigationStack {
      List {
        Section("Global") {
          Stepper {
            Text("BPM: \(Int(self.bpm))")
          } onIncrement: {
            self.bpm += 1
          } onDecrement: {
            self.bpm -= 1

            if self.bpm < 0 {
              self.bpm = 0
            }
          }.onChange(of: self.bpm) { _, newValue in
            UserDefaults.standard.setValue(newValue, forKey: "BPM")
          }

          Toggle(isOn: self.$bpmSync) {
            Text("Sync BPM")
          }.onChange(of: self.bpmSync) { _, newValue in
            UserDefaults.standard.setValue(newValue, forKey: "BPMSync")
          }

          Picker("Key", selection: self.$selectedScaleKey) {
            ForEach(Notes, id: \.self.hashValue) { note in
              Text(getNoteLabel(note: note)).tag(note)
            }
          }.onChange(of: self.selectedScaleKey) {
            UserDefaults.standard.setValue(self.selectedScaleKey.rawValue, forKey: "ScaleKey")
            self.selectedScaleInKey = getScaleInKey(scale: self.selectedScale, key: self.selectedScaleKey)
          }

          Picker("Scale", selection: self.$selectedScale) {
            ForEach(Scales, id: \.self.hashValue) { scale in
              Text(scale.name).tag(scale)
            }
          }.onChange(of: self.selectedScale) { _, newValue in
            UserDefaults.standard.setValue(self.selectedScale.name, forKey: "Scale")
            self.selectedScaleInKey = getScaleInKey(scale: newValue, key: self.selectedScaleKey)
          }

          Slider(
            value: self.$volume,
            in: 0 ... 100,
            step: 1
          ) {
            Text("Volume")
          } minimumValueLabel: {
            Text("\(Image(systemName: "speaker"))")
          } maximumValueLabel: {
            Text("\(Image(systemName: "speaker.wave.3"))")
          }.onChange(of: self.volume) { _, newValue in
            UserDefaults.standard.setValue(newValue, forKey: "Volume")
            engine?.mainMixerNode.outputVolume = newValue / 100
          }

          Text("Frequencies: \(self.frequencyHistory)")
        }

        Section("Synths") {
          if self.synths.count == 0 {
            Text("No synths added")
          }

          ForEach(self.synths) { synth in
            NavigationLink {
              SynthView(synth: synth)
            } label: {
              Text(synth.name)
            }
          }
        }

        Section("Notes") {
          NavigationLink {
            NotesView(synths: self.synths, noteTable: noteTable, scale: self.selectedScaleInKey)
          } label: {
            Text("Play")
          }.disabled(synths.count == 0)
        }

        Section("Sequencer") {
          NavigationLink {
            SequencerView(synths: self.synths,
                          sequences: self.sequences,
                          noteTable: noteTable,
                          noteTableSize: noteTableSize,
                          scale: self.selectedScaleInKey,
                          beatSignal: self.beatSignal)
          } label: {
            Text("Edit")
          }.disabled(synths.count == 0) // || synths.first { synth in synth.playMode == .sequencer } == nil)
        }

        Section("Settings") {
          Toggle(isOn: self.$enableNetworking) {
            Text("Networking")
          }.onChange(of: self.enableNetworking) { _, newValue in
            UserDefaults.standard.setValue(newValue, forKey: "EnableNetworking")
            daco?.shouldPostData = newValue
          }
        }
      }.toolbar {
        ToolbarItem {
          Button(action: self.addSynth) {
            Label("Add", systemImage: "plus")
          }.disabled(engine == nil)
        }
        ToolbarItem {
          Button(action: self.stop) {
            Label("Stop", systemImage: "stop")
          }.disabled(self.fullyStopped)
        }
        ToolbarItem {
          Button(action: self.start) {
            Label("Start", systemImage: "play")
          }.disabled(self.playStarting || self.playing)
        }
      }
    }.onAppear(perform: {
      self.initEngine()
    })
  }

  private func addSynth() {
    DispatchQueue.main.async {
      let synth: Synth = .init(engine: engine!, sampleRate: Float(inputFormat!.sampleRate), volume: 0.4, polyphony: 6)
      synth.start {}

      let oscillator: Oscillator = .init(engine: engine!, sampleRate: Float(inputFormat!.sampleRate), type: .sine, amplitude: 0.6)
      oscillator.start()

      let oscillatorTwo: Oscillator = .init(engine: engine!, sampleRate: Float(inputFormat!.sampleRate), type: .triangle, amplitude: 0.3)
      oscillatorTwo.start()

      synth.addOscillator([oscillator, oscillatorTwo])

      addSynth(synth: synth)
    }
  }

  private func addSynth(synth: Synth) {
    synths.append(synth)

    try! synth.connect(to: engine!.mainMixerNode, format: inputFormat)
    synth.bpm = bpm

    synthPlayModes[synth.id] = .device
    sequences[synth.id] = .init()
  }

  private func start() {
    for synth in synths {
      synth.stopped = false
    }

    if playStarting || playing {
      return
    }

    fullyStopped = false
    playStarting = true

    DispatchQueue.main.async {
      if daco == nil {
        daco = try! .init(server: defaultServer, dataToCollect: nil, shouldPostData: self.enableNetworking)
      }

      do {
        try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
        try AVAudioSession.sharedInstance().setActive(true)
      } catch {
      }

      self.initEngine()

      if !engine!.isRunning {
        do {
          try engine!.start()
        } catch {}
      }

      self.playing = true
      self.playStarting = false
    }
  }

  private func initEngine() {
    if engine != nil {
      return
    }

    engine = AVAudioEngine()
    let mainMixer = engine!.mainMixerNode
    let output = engine!.outputNode
    let outputFormat = output.inputFormat(forBus: 0)
    let sampleRate = Float(outputFormat.sampleRate)

    inputFormat = .init(
      commonFormat: outputFormat.commonFormat,
      sampleRate: outputFormat.sampleRate,
      channels: 1,
      interleaved: outputFormat.isInterleaved
    )

    var yaw: Float = 0.0

    let basicSynth: SynthBasic = .init(engine: engine!, sampleRate: sampleRate, volume: 0.4)
    basicSynth.start {
      // roll/yaw (-180 : 180)
      // pitch (-90 : 90)

      yaw = Float(abs(max(min(180 * (daco?.motion.deviceMotion?.attitude.yaw ?? 0) / Double.pi, 180), -180)) / 180)
      basicSynth.yaw = yaw
    }
    addSynth(synth: basicSynth)

    let sparkSynth: SynthSpark = .init(engine: engine!, sampleRate: sampleRate, volume: 0.5)
    sparkSynth.start()
    addSynth(synth: sparkSynth)

    let ambiSynth: SynthAmbi = .init(engine: engine!, sampleRate: sampleRate, volume: 0.4)
    ambiSynth.start {
      ambiSynth.yaw = yaw
    }
    addSynth(synth: ambiSynth)

    let dustSynth: SynthDust = .init(engine: engine!, sampleRate: sampleRate, volume: 0.25)
    dustSynth.start()
    addSynth(synth: dustSynth)

    let speechNode: SpeechNode = .init(format: AVAudioFormat(
      commonFormat: inputFormat!.commonFormat,
      sampleRate: inputFormat!.sampleRate / 2,
      channels: 1,
      interleaved: inputFormat!.isInterleaved
    )!)
    speechNode.connect(engine: engine!, to: mainMixer)

    queueSpeaking(speechNode: speechNode, first: true)

    engine!.connect(mainMixer, to: output, format: outputFormat)
    mainMixer.outputVolume = volume / 100

    var bar = 0
    var beat: UInt8 = 0
    var beatStep: UInt8 = 0
    let beatTotalSteps: UInt8 = 64
    func startBPMTimer() {
      Timer.scheduledTimer(withTimeInterval: Double(bpm) / 60.0 / Double(beatTotalSteps), repeats: true) { timer in
        if !self.playing {
          return
        }

//        if beatStep % 64 == 0 {
//          print("Whole")
//        } else if beatStep % 32 == 0 {
//          print("1/2th")
//        } else if beatStep % 16 == 0 {
//          print("1/4th")
//        } else if beatStep % 8 == 0 {
//          print("1/8th")
//        } else if beatStep % 4 == 0 {
//          print("1/16th")
//        } else if beatStep % 2 == 0 {
//          print("1/32th")
//        } else {
//          print("1/64th")
//        }

        if dustSynth.playMode == .device {
          if beatStep % 32 == 0 {
            dustSynth.playNote(frequency: noteTable[Int.random(in: 4 ... 5)][self.selectedScaleInKey.notes.randomElement()!])
          } else if beatStep % 32 == 8 {
            dustSynth.playNote(frequency: noteTable[Int.random(in: 4 ... 5)][self.selectedScaleInKey.notes.randomElement()!])
          } else if beatStep % 32 == 16 {
            dustSynth.playNote(frequency: noteTable[Int.random(in: 4 ... 5)][self.selectedScaleInKey.notes.randomElement()!])
          }
        } else if dustSynth.playMode == .sequencer {}

        if ambiSynth.playMode == .device {
          if beatStep == 0 && beat == 0 && bar % 4 == 0 {
            let rootNote = selectedScaleInKey.notes.randomElement()!

            ambiSynth.playNote(frequency: noteTable[3][rootNote])
            ambiSynth.playNote(frequency: noteTable[2][self.selectedScaleInKey.notes.randomElement()!])
            ambiSynth.playNote(frequency: noteTable[1][rootNote])
          }
        } else if ambiSynth.playMode == .sequencer {}

        if basicSynth.playMode == .device {
          if !self.bpmSync || beatStep % 4 == 0 {
            let newFrequency: Float = noteTable[
              (abs(Int((daco?.motion.deviceMotion?.attitude.pitch ?? 0) * 10)) % 3) + 2
            ][
              self.selectedScaleInKey.notes[abs(Int((daco?.motion.deviceMotion?.attitude.roll ?? 0) * 10)) % self.selectedScaleInKey.notes.count]
            ]

            if self.frequencyHistory[self.frequencyHistory.count - 1] != newFrequency {
              self.frequencyHistory.append(newFrequency)
              basicSynth.playNote(frequency: newFrequency)

              if self.frequencyHistory.count > 10 {
                self.frequencyHistory.removeSubrange(0 ... (self.frequencyHistory.count - 11))
              }
            }
          }
        } else if basicSynth.playMode == .sequencer {}

        if sparkSynth.playMode == .device {
          if beatStep % 64 == 0 {
            sparkSynth.playNote(frequency: noteTable[Int.random(in: 3 ... 5)][self.selectedScaleInKey.notes.randomElement()!])
          } else if beatStep % 64 == 16 {
            sparkSynth.playNote(frequency: noteTable[Int.random(in: 3 ... 5)][self.selectedScaleInKey.notes.randomElement()!])
          } else if beatStep % 64 == 32 {
            sparkSynth.playNote(frequency: noteTable[Int.random(in: 3 ... 5)][self.selectedScaleInKey.notes.randomElement()!])
          }
        } else if sparkSynth.playMode == .sequencer {}

        beatStep += 1

        if beatStep >= beatTotalSteps {
          beatStep = 0
          beat += 1

          self.beatSignal.toggle()

          if beat >= 4 {
            beat = 0
            bar += 1
          }
        }

        if timer.timeInterval != Double(bpm) / 60.0 / Double(beatTotalSteps) {
          timer.invalidate()

          startBPMTimer()
        }
      }
    }
    startBPMTimer()
  }

  private func queueSpeaking(speechNode: SpeechNode, first: Bool = false) {
    let delay = DispatchTimeInterval.seconds(first ? 2 : Int.random(in: 20 ... 60))

    DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
      if self.enableNetworking {
        postSpeak { data in
          if data != nil && playing {
            speechNode.speak(string: data! as String, voiceIdentifier: SpeechNode.voiceIdentifiers.randomElement()!)
          }

          self.queueSpeaking(speechNode: speechNode)
        }
      } else {
        self.queueSpeaking(speechNode: speechNode)
      }
    }
  }

  private func stop() {
    daco?.shouldPostData = false

    if !playing {
      for synth in synths {
        synth.stopped = true
      }

      fullyStopped = true
      engine?.stop()

      do {
        try AVAudioSession.sharedInstance().setActive(false)
      } catch {}
    }

    playing = false
  }
}
