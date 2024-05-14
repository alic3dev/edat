//
//  ContentView.swift
//  Edat
//
//  Created by Alice Grace on 5/3/24.
//

import SwiftData
import SwiftUI

import AVFoundation
import CoreMotion

import zer0_ios

private var engine: AVAudioEngine?
private var inputFormat: AVAudioFormat?
private var dataCollector: DataCollector?
private var noteTable: [[Float]] = createNoteTable(frequencyRoot: .magic)

struct ContentView: View {
  @Environment(\.modelContext) private var modelContext

  @State private var enableNetworking: Bool = getUserDefault(key: "EnableNetworking", defaultValue: true)

  @State private var volume: Float = getUserDefault(key: "Volume", defaultValue: 100.0)
  @State private var bpm: Float = getUserDefault(key: "BPM", defaultValue: 90.0)
  @State private var bpmSync: Bool = getUserDefault(key: "BPMSync", defaultValue: true)
  @State private var frequencyHistory: [Float] = [0.0]

  @State private var selectedScaleKey: Note = getInitialSelectedScaleKey()
  @State private var selectedScale: Scale = getInitialSelectedScale()
  @State private var selectedScaleInKey: Scale = getScaleInKey(scale: getInitialSelectedScale(), key: getInitialSelectedScaleKey())

  @State private var synths: [Synth] = []

  @State private var playStarting: Bool = false
  @State private var playing: Bool = false
  @State private var fullyStopped: Bool = true

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

        Section("Settings") {
          Toggle(isOn: self.$enableNetworking) {
            Text("Networking")
          }.onChange(of: self.enableNetworking) { _, newValue in
            UserDefaults.standard.setValue(newValue, forKey: "EnableNetworking")
            dataCollector?.shouldPostData = newValue
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
    }
  }

  private func addSynth() {
    let synth: Synth = .init(engine: engine!, sampleRate: Float(inputFormat!.sampleRate))
    synth.start {}

    synths.append(synth)
  }

  private func addSynth(synth: Synth) {
    synths.append(synth)
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
      if dataCollector == nil {
        dataCollector = .init()
      }

      dataCollector?.shouldPostData = self.enableNetworking

      do {
        try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
        try AVAudioSession.sharedInstance().setActive(true)
      } catch {}

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

    let basicSynth: SynthBasic = .init(engine: engine!, sampleRate: sampleRate, volume: 0.5)
    basicSynth.start {
      // roll/yaw (-180 : 180)
      // pitch (-90 : 90)

      yaw = Float(abs(max(min(180 * (dataCollector?.motion.deviceMotion?.attitude.yaw ?? 0) / Double.pi, 180), -180)) / 180)

      basicSynth.yaw = yaw

      let newFrequency: Float = noteTable[
        (abs(Int((dataCollector?.motion.deviceMotion?.attitude.pitch ?? 0) * 10)) % 3) + 2
      ][
        self.selectedScaleInKey.notes[abs(Int((dataCollector?.motion.deviceMotion?.attitude.roll ?? 0) * 10)) % self.selectedScaleInKey.notes.count]
      ]

      if self.frequencyHistory[self.frequencyHistory.count - 1] != newFrequency {
        self.frequencyHistory.append(newFrequency)
        basicSynth.playNote(frequency: newFrequency)

        if self.frequencyHistory.count > 10 {
          self.frequencyHistory.removeSubrange(0 ... (self.frequencyHistory.count - 11))
        }
      }
    }
    addSynth(synth: basicSynth)

    var lastSparkUpdate = Date.now.timeIntervalSince1970
    let sparkSynth: SynthSpark = .init(engine: engine!, sampleRate: sampleRate, volume: 0.5)
    sparkSynth.start {
      if Date.now.timeIntervalSince1970 - lastSparkUpdate > 1 {
        sparkSynth.playNote(frequency: noteTable[Int.random(in: 3 ... 5)][self.selectedScaleInKey.notes.randomElement()!])

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
          sparkSynth.playNote(frequency: noteTable[Int.random(in: 3 ... 5)][self.selectedScaleInKey.notes.randomElement()!])
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
          sparkSynth.playNote(frequency: noteTable[Int.random(in: 3 ... 5)][self.selectedScaleInKey.notes.randomElement()!])
        }

        lastSparkUpdate = Date.now.timeIntervalSince1970
      }
    }
    addSynth(synth: sparkSynth)

    var lastAmbiUpdate = Date.now.timeIntervalSince1970
    let ambiSynth: SynthAmbi = .init(engine: engine!, sampleRate: sampleRate, volume: 0.5)
    ambiSynth.start {
      ambiSynth.yaw = yaw

      if Date.now.timeIntervalSince1970 - lastAmbiUpdate > 15 {
        let rootNote = selectedScaleInKey.notes.randomElement()!

        ambiSynth.playNote(frequency: noteTable[3][rootNote])
        ambiSynth.playNote(frequency: noteTable[2][self.selectedScaleInKey.notes.randomElement()!])
        ambiSynth.playNote(frequency: noteTable[1][rootNote])

        lastAmbiUpdate = Date.now.timeIntervalSince1970
      }
    }
    addSynth(synth: ambiSynth)

    for synth in synths {
      try! synth.connect(to: mainMixer, format: inputFormat)
    }

    let rootNote = selectedScaleInKey.notes.randomElement()!
    ambiSynth.playNote(frequency: noteTable[3][rootNote])
    ambiSynth.playNote(frequency: noteTable[2][selectedScaleInKey.notes.randomElement()!])
    ambiSynth.playNote(frequency: noteTable[1][rootNote])

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
  }

  private func queueSpeaking(speechNode: SpeechNode, first: Bool = false) {
    let delay = DispatchTimeInterval.seconds(first ? 2 : Int.random(in: 20 ... 60))

    DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
      if self.enableNetworking {
        postSpeak { data in
          if data != nil {
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
    dataCollector?.shouldPostData = false

    if playing {
      for synth in synths {
        synth.stopped = true
      }
    } else {
      fullyStopped = true
      engine?.stop()

      do {
        try AVAudioSession.sharedInstance().setActive(false)
      } catch {}
    }

    playing = false
  }
}

#Preview {
  ContentView()
    .modelContainer(for: Item.self, inMemory: true)
}
