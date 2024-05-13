//
//  SpeechNode.swift
//  Edat
//
//  Created by Alice Grace on 5/5/24.
//

import AVFoundation
import Foundation

enum SpeechNodeError: Error {
  case invalidVoiceIdentifier(String)
}

var speechSynthesizer: AVSpeechSynthesizer = .init()

final class SpeechNode {
  static let voiceIdentifiers: [String] = [
    "com.apple.voice.enhanced.en-US.Noelle",
    "com.apple.voice.premium.en-US.Zoe",
    "com.apple.speech.synthesis.voice.Deranged"
  ]

  private let audioPlayerNode: AVAudioPlayerNode = .init()
  private let delay: AVAudioUnitDelay = .init()
  private let reverb: AVAudioUnitReverb = .init()

  private let format: AVAudioFormat

  private var selectedVoiceIdentifier: String = SpeechNode.voiceIdentifiers[0]

  init(format: AVAudioFormat) {
    self.format = format

    self.delay.delayTime = 0.05
    self.delay.feedback = 50
    self.delay.lowPassCutoff = 12000
    self.delay.wetDryMix = 23

    self.reverb.loadFactoryPreset(.smallRoom)
    self.reverb.wetDryMix = 40
  }

  func setVoiceIdentifier(voiceIdentifier: String) throws {
    if SpeechNode.voiceIdentifiers.contains(voiceIdentifier) {
      self.selectedVoiceIdentifier = voiceIdentifier
    } else {
      throw SpeechNodeError.invalidVoiceIdentifier("Invalid voice identifier")
    }
  }

  func speak(string: String, voiceIdentifier: String? = nil) {
    let utterance = AVSpeechUtterance(string: string)
    utterance.voice = AVSpeechSynthesisVoice(identifier: voiceIdentifier != nil ? voiceIdentifier! : self.selectedVoiceIdentifier)
//    utterance.rate = AVSpeechUtteranceDefaultSpeechRate / 1.75
//    utterance.pitchMultiplier = 0.66
    utterance.volume = 0.40

    speechSynthesizer.write(utterance) { audioBuffer in
      self.audioPlayerNode.scheduleBuffer(audioBuffer as! AVAudioPCMBuffer)

      if !self.audioPlayerNode.isPlaying {
        self.audioPlayerNode.play()
      }
    }
  }

  func connect(engine: AVAudioEngine, to: AVAudioNode) {
    engine.attach(self.audioPlayerNode)
    engine.attach(self.delay)
    engine.attach(self.reverb)

    engine.connect(self.audioPlayerNode, to: self.delay, format: self.format)
    engine.connect(self.delay, to: self.reverb, format: self.format)
    engine.connect(self.reverb, to: to, format: self.format)
  }
}
