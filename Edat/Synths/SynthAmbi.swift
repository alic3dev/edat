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

    self.attack = 10
    self.decay = 5
    self.sustain = 0.5
    self.sustainDuration = 2.5
    self.release = 2.5

    let delay: AVAudioUnitDelay = .init()
    delay.delayTime = 1
    delay.feedback = 49
    delay.lowPassCutoff = 1400
    delay.wetDryMix = 50
    self.engine.attach(delay)
    self.delays.append(delay)

    let reverb: AVAudioUnitReverb = .init()
    reverb.loadFactoryPreset(.cathedral)
    reverb.wetDryMix = 50
    self.engine.attach(reverb)
    self.reverbs.append(reverb)
  }

  override func start(onRender: @escaping onSynthRenderFunc) {
    super.start(onRender: onRender)

    let oscillator: Oscillator = .init(engine: self.engine, sampleRate: self.sampleRate, amplitude: 0.5)
    oscillator.start {
      { phaseValue in
        let sine = SignalSine.generate(phaseValue) * self.yaw
        let triangle = SignalTriangle.generate(phaseValue) * 1.0 - self.yaw

        return sine + triangle
      }
    }

    self.addOscillator(oscillator)
  }

  override func connect(to: AVAudioNode, format: AVAudioFormat?) throws {
    try! super.connect(to: self.reverbs[0], format: format)

    self.engine.connect(self.reverbs[0], to: self.delays[0], format: format)
    self.engine.connect(self.delays[0], to: to, format: format)
  }
}
