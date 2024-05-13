//
//  Basic.swift
//  Edat
//
//  Created by Alice Grace on 5/12/24.
//

import Foundation

import AVFAudio
import zer0_ios

final class SynthBasic {
  private let engine: AVAudioEngine
  private let sampleRate: Float
  private let synth: Synth

  public let delay: AVAudioUnitDelay = .init()
  public let reverb: AVAudioUnitReverb = .init()

  public var yaw: Float = 0.0

  init(engine: AVAudioEngine, sampleRate: Float) {
    self.engine = engine
    self.sampleRate = sampleRate

    self.synth = .init(engine: self.engine, sampleRate: self.sampleRate, polyphony: 6)

    self.delay.delayTime = 1
    self.delay.feedback = 30
    self.delay.lowPassCutoff = 1400
    self.delay.wetDryMix = 25
    self.engine.attach(self.delay)

    self.reverb.loadFactoryPreset(.mediumRoom)
    self.reverb.wetDryMix = 25
    self.engine.attach(self.reverb)
  }

  func start(onRender: @escaping onSynthRenderFunc) {
    self.synth.start(onRender: onRender)

    let oscillator: Oscillator = .init(engine: self.engine, sampleRate: self.sampleRate, amplitude: 0.6)
    oscillator.start {
      { phaseValue in
        let sine = SignalSine.generate(phaseValue) * 1.0 - self.yaw
        let triangle = SignalTriangle.generate(phaseValue) * self.yaw

        return sine + triangle
      }
    }

    let oscillatorTwo: Oscillator = .init(engine: self.engine, sampleRate: self.sampleRate, amplitude: 0.15)
    oscillatorTwo.start {
      { phaseValue in
        SignalSawtoothUp.generate(phaseValue) * min(self.yaw, 0.25)
      }
    }

    self.synth.addOscillator([oscillator, oscillatorTwo])
  }

  func playNote(frequency: Float) {
    self.synth.playNote(frequency: frequency)
  }

  func connct(to: AVAudioNode, format: AVAudioFormat?) throws {
    try! self.synth.connect(to: self.delay, format: format)

    self.engine.connect(self.delay, to: self.reverb, format: format)
    self.engine.connect(self.reverb, to: to, format: format)
  }
}
