//
//  SynthDust.swift
//  Edat
//
//  Created by Alice Grace on 5/17/24.
//

import Foundation

import AVFAudio
import zer0_ios

final class SynthDust: Synth {
  private let engine: AVAudioEngine
  private let sampleRate: Float

  public var yaw: Float = 0.0

  init(engine: AVAudioEngine, sampleRate: Float, volume: Float = 1.0) {
    self.engine = engine
    self.sampleRate = sampleRate

    super.init(engine: self.engine, sampleRate: self.sampleRate, volume: volume, polyphony: 6)

    self.name = "Dust Synth"

    self.attack = 1.2
    self.decay = 0.3
    self.sustain = 0.25
    self.sustainDuration = 0.1
    self.decay = 0.2

    let delay: AVAudioUnitDelay = .init()
    self.engine.attach(delay)
    delay.delayTime = 0.333
    delay.feedback = 75
    delay.lowPassCutoff = 400
    delay.wetDryMix = 100

    self.addEffect(effect: delay)

    let reverb: AVAudioUnitReverb = .init()
    self.engine.attach(reverb)
    reverb.loadFactoryPreset(.cathedral)
    reverb.wetDryMix = 100

    self.addEffect(effect: reverb)
  }

  override func start(onRender: @escaping onSynthRenderFunc) {
    super.start(onRender: onRender)

    let oscillator: Oscillator = .init(engine: self.engine, sampleRate: self.sampleRate, amplitude: 0.5)
    oscillator.start {
      { phaseValue in
        SignalTriangle.generate(phaseValue)
      }
    }

    let oscillatorTwo: Oscillator = .init(engine: self.engine, sampleRate: self.sampleRate, amplitude: 0.15)
    oscillatorTwo.start {
      { phaseValue in
        SignalSquare.generate(phaseValue)
      }
    }

    super.addOscillator([oscillator, oscillatorTwo])
  }
}
