//
//  AmbiSynth.swift
//  Edat
//
//  Created by Alice Grace on 5/13/24.
//

import Foundation

import AVFAudio
import zer0_ios

final class SynthAmbi: Synth {
  private let engine: AVAudioEngine
  private let sampleRate: Float

  public var yaw: Float = 0.0

  init(engine: AVAudioEngine, sampleRate: Float, volume: Float = 1.0) {
    self.engine = engine
    self.sampleRate = sampleRate

    super.init(engine: self.engine, sampleRate: self.sampleRate, volume: volume, polyphony: 6)

    self.name = "Ambi Synth"

    self.attack = 6.6666666667 * 2
    self.decay = 3.3333333333 * 8
    self.sustain = 0.5
    self.sustainDuration = 1.6666666667 * 5
    self.release = 1.6666666667 * 5

    let reverb: AVAudioUnitReverb = .init()
    self.engine.attach(reverb)
    reverb.loadFactoryPreset(.cathedral)
    reverb.wetDryMix = 50
    self.addEffect(effect: reverb)

    let delay: AVAudioUnitDelay = .init()
    self.engine.attach(delay)
    delay.delayTime = 1
    delay.feedback = 49
    delay.lowPassCutoff = 1400
    delay.wetDryMix = 50
    self.addEffect(effect: delay)
  }

  override func start(onRender: @escaping onSynthRenderFunc) {
    super.start(onRender: onRender)

    let oscillator: Oscillator = .init(engine: self.engine, sampleRate: self.sampleRate, amplitude: 0.5)
    oscillator.start {
      { phaseValue in
        let sine = SignalSine.generate(phaseValue) * self.yaw
        let triangle = SignalTriangle.generate(phaseValue) * (1.0 - self.yaw)

        return min(max(sine + triangle, -1), 1)
      }
    }

    super.addOscillator(oscillator)
  }
}
