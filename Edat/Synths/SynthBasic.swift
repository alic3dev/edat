//
//  Basic.swift
//  Edat
//
//  Created by Alice Grace on 5/12/24.
//

import Foundation

import AVFAudio
import zer0_ios

final class SynthBasic: Synth {
  private let engine: AVAudioEngine
  private let sampleRate: Float

  public var yaw: Float = 0.0

  init(engine: AVAudioEngine, sampleRate: Float, volume: Float = 1.0) {
    self.engine = engine
    self.sampleRate = sampleRate

    super.init(engine: self.engine, sampleRate: self.sampleRate, volume: volume, polyphony: 6)

    self.name = "Basic Synth"

    let delay: AVAudioUnitDelay = .init()
    delay.delayTime = 1
    delay.feedback = 30
    delay.lowPassCutoff = 1400
    delay.wetDryMix = 25
    self.engine.attach(delay)
    self.delays.append(delay)

    let reverb: AVAudioUnitReverb = .init()
    reverb.loadFactoryPreset(.mediumRoom)
    reverb.wetDryMix = 10
    self.engine.attach(reverb)
    self.reverbs.append(reverb)
  }

  override func start(onRender: @escaping onSynthRenderFunc) {
    super.start(onRender: onRender)

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

    super.addOscillator([oscillator, oscillatorTwo])
  }

  override func connect(to: AVAudioNode, format: AVAudioFormat?) throws {
    try! super.connect(to: self.delays[0], format: format)

    self.engine.connect(self.delays[0], to: self.reverbs[0], format: format)
    self.engine.connect(self.reverbs[0], to: to, format: format)
  }
}
