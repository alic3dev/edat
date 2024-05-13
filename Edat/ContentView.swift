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

var engine: AVAudioEngine?
var dataCollector: DataCollector?
var noteTable: [[Float]] = createNoteTable(frequencyRoot: .magic)

struct ContentView: View {
  @Environment(\.modelContext) private var modelContext
  @Query private var items: [Item]

  @State private var bpm: Float = 90
  @State private var playStarting: Bool = false
  @State private var playing: Bool = false
  @State private var frequencyHistory: [Float] = [0.0]

  var body: some View {
    NavigationStack {
      List {
        Text("BPM: \(self.bpm)")
        Text("Frequencies: \(self.frequencyHistory)")
      }
      .toolbar {
        ToolbarItem {
          if self.playing {
            Button(action: self.stop) {
              Label("Stop", systemImage: "stop")
            }
          } else {
            Button(action: self.start) {
              Label("Start", systemImage: "play")
            }.disabled(self.playStarting)
          }
        }
      }
    }
  }

  private func start() {
    if self.playStarting || self.playing {
      return
    }

    self.playStarting = true

    DispatchQueue.main.async {
      if dataCollector == nil {
        dataCollector = .init()
      }

      dataCollector?.shouldPostData = true

      do {
        try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
        try AVAudioSession.sharedInstance().setActive(true)
      } catch {}

      self.initEngine()

      do {
        try engine!.start()
      } catch {}

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

    let inputFormat = AVAudioFormat(
      commonFormat: outputFormat.commonFormat,
      sampleRate: outputFormat.sampleRate,
      channels: 1,
      interleaved: outputFormat.isInterleaved
    )

//    var serverDataLastUpdate: Date = dataCollector?.serverDataLastUpdate ?? Date.now
//    var serverDataLooped = 0
//
//    let srcDataNode = AVAudioSourceNode { _, _, frameCount, audioBufferList -> OSStatus in
//      let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)
//
//      let serverData: Data? = dataCollector?.serverData ?? nil
//
//      if serverDataLastUpdate >= dataCollector!.serverDataLastUpdate {
//        serverDataLooped += 1
//      } else {
//        serverDataLooped = 0
//      }
//
//      if dataCollector == nil || serverData == nil || serverData!.count <= 0 || serverDataLooped >= 10 {
//        for frame in 0 ..< Int(frameCount) {
//          // Set the same value on all channels (due to the inputFormat, there's only one channel though).
//          for buffer in ablPointer {
//            let buf: UnsafeMutableBufferPointer<Float> = UnsafeMutableBufferPointer(buffer)
//            buf[frame] = 0
//          }
//        }
//
//        return noErr
//      }
//
//      serverDataLastUpdate = dataCollector!.serverDataLastUpdate
//
//      // frameCount appears to always be 1024
//
//      let iterationAmount = Float(serverData!.count) / Float(frameCount)
//      var iterationValue: Float = 0
//      let amplitude: Float = 0.5
//
//      for frame in 0 ..< Int(frameCount) {
//        let dataValue: UInt8 = serverData![min(serverData!.count - 1, Int(floor(iterationValue)))]
//        let value: Float = (max(0.0, min(255.0, Float(dataValue))) - 127.5) / 127.5 * amplitude
//
//        // Set the same value on all channels (due to the inputFormat, there's only one channel though).
//        for buffer in ablPointer {
//          let buf: UnsafeMutableBufferPointer<Float> = UnsafeMutableBufferPointer(buffer)
//          buf[frame] = value
//        }
//
//        iterationValue += iterationAmount
//      }
//
//      return noErr
//    }
//
//    srcDataNode.volume = 0.5
//
//    engine!.attach(srcDataNode)
//
//    let delayTwo = AVAudioUnitDelay()
//    delayTwo.delayTime = 0.2
//    delayTwo.feedback = 50
//    delayTwo.lowPassCutoff = 7000
//    delayTwo.wetDryMix = 45
//    engine!.attach(delayTwo)
//
//    let reverbTwo = AVAudioUnitReverb()
//    reverbTwo.loadFactoryPreset(.plate)
//    reverbTwo.wetDryMix = 90
//    engine!.attach(reverbTwo)
//
//    let b = AVAudioUnitEQ(numberOfBands: 1)
//    b.bands[0].filterType = .lowPass
//    b.bands[0].bypass = false
//    b.bands[0].bandwidth = 0
//    b.bands[0].frequency = 300
//    b.bands[0].gain = 2
//    engine!.attach(b)
//
//    engine!.connect(srcDataNode, to: delayTwo, format: inputFormat)
//
//    engine!.connect(delayTwo, to: reverbTwo, format: inputFormat)
//    engine!.connect(reverbTwo, to: b, format: inputFormat)
//    engine!.connect(b, to: mainMixer, format: inputFormat)

    var yaw: Float = 0.0

    let basicSynth: SynthBasic = .init(engine: engine!, sampleRate: sampleRate)
    basicSynth.start {
      // roll/yaw (-180 : 180)
      // pitch (-90 : 90)

      yaw = Float(abs(max(min(180 * (dataCollector?.motion.deviceMotion?.attitude.yaw ?? 0) / Double.pi, 180), -180)) / 180)

      basicSynth.yaw = yaw

      let newFrequency: Float = noteTable[
        (abs(Int((dataCollector?.motion.deviceMotion?.attitude.pitch ?? 0) * 10)) % 3) + 2
      ][
        ScaleMinor.notes[abs(Int((dataCollector?.motion.deviceMotion?.attitude.roll ?? 0) * 10)) % ScaleMinor.notes.count]
      ]

      if self.frequencyHistory[self.frequencyHistory.count - 1] != newFrequency {
        self.frequencyHistory.append(newFrequency)
        basicSynth.playNote(frequency: newFrequency)

        if self.frequencyHistory.count > 10 {
          self.frequencyHistory.removeSubrange(0 ... (self.frequencyHistory.count - 11))
        }
      }
    }
    try! basicSynth.connct(to: mainMixer, format: inputFormat)

    var lastUpdate = Date.now.timeIntervalSince1970
    let ambiSynth: SynthAmbi = .init(engine: engine!, sampleRate: sampleRate)
    ambiSynth.start {
      ambiSynth.yaw = yaw

      if Date.now.timeIntervalSince1970 - lastUpdate > 15 {
        let rootNote = ScaleMinor.notes.randomElement()!

        ambiSynth.playNote(frequency: noteTable[3][rootNote])
        ambiSynth.playNote(frequency: noteTable[2][ScaleMinor.notes.randomElement()!])
        ambiSynth.playNote(frequency: noteTable[1][rootNote])

        lastUpdate = Date.now.timeIntervalSince1970
      }
    }
    try! ambiSynth.connct(to: mainMixer, format: inputFormat)
    let rootNote = ScaleMinor.notes.randomElement()!

    ambiSynth.playNote(frequency: noteTable[3][rootNote])
    ambiSynth.playNote(frequency: noteTable[2][ScaleMinor.notes.randomElement()!])
    ambiSynth.playNote(frequency: noteTable[1][rootNote])

    let speechNode: SpeechNode = .init(format: AVAudioFormat(
      commonFormat: inputFormat!.commonFormat,
      sampleRate: inputFormat!.sampleRate / 2,
      channels: 1,
      interleaved: inputFormat!.isInterleaved
    )!)
    speechNode.connect(engine: engine!, to: mainMixer)

    self.queueSpeaking(speechNode: speechNode, first: true)

    engine!.connect(mainMixer, to: output, format: outputFormat)
    mainMixer.outputVolume = 1
  }

  private func queueSpeaking(speechNode: SpeechNode, first: Bool = false) {
    let delay = DispatchTimeInterval.seconds(first ? 2 : Int.random(in: 20 ... 60))

    DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
      postSpeak { data in
        if data != nil {
          speechNode.speak(string: data! as String, voiceIdentifier: SpeechNode.voiceIdentifiers.randomElement()!)
        }

        self.queueSpeaking(speechNode: speechNode)
      }
    }
  }

  private func stop() {
    dataCollector?.shouldPostData = false

    engine?.stop()

    do {
      try AVAudioSession.sharedInstance().setActive(false)
    } catch {}

    self.playing = false
  }
}

#Preview {
  ContentView()
    .modelContainer(for: Item.self, inMemory: true)
}
