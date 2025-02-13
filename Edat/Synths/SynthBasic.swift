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
    self.engine.attach(delay)
    delay.delayTime = 1
    delay.feedback = 30
    delay.lowPassCutoff = 1400
    delay.wetDryMix = 25

    self.addEffect(effect: delay)

    let reverb: AVAudioUnitReverb = .init()
    self.engine.attach(reverb)
    reverb.loadFactoryPreset(.mediumRoom)
    reverb.wetDryMix = 10

    self.addEffect(effect: reverb)
  }

  override func start(onRender: @escaping onSynthRenderFunc) {
    super.start(onRender: onRender)

    let oscillator: Oscillator = .init(engine: self.engine, sampleRate: self.sampleRate, amplitude: 0.6)
    oscillator.start {
      { phaseValue in
        let sine = SignalSine.generate(phaseValue) * (1.0 - self.yaw)
        let triangle = SignalTriangle.generate(phaseValue) * self.yaw

        return min(max(sine + triangle, -1), 1)
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
}
