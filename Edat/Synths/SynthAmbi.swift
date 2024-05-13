//
//  AmbiSynth.swift
//  Edat
//
//  Created by Alice Grace on 5/13/24.
//

import Foundation

import AVFAudio
import zer0_ios

final class SynthAmbi {
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
    self.synth.attack = 10
    self.synth.decay = 5
    self.synth.sustain = 0.5
    self.synth.sustainDuration = 2.5
    self.synth.release = 2.5
//    self.synth.resetVolumeOnNote = false

    self.delay.delayTime = 1
    self.delay.feedback = 49
    self.delay.lowPassCutoff = 1400
    self.delay.wetDryMix = 50
    self.engine.attach(self.delay)

    self.reverb.loadFactoryPreset(.cathedral)
    self.reverb.wetDryMix = 50
    self.engine.attach(self.reverb)
  }

  func start(onRender: @escaping onSynthRenderFunc) {
    self.synth.start(onRender: onRender)

    let oscillator: Oscillator = .init(engine: self.engine, sampleRate: self.sampleRate, amplitude: 0.5)
    oscillator.start {
      { phaseValue in
        let sine = SignalSine.generate(phaseValue) * self.yaw
        let triangle = SignalTriangle.generate(phaseValue) * 1.0 - self.yaw

        return sine + triangle
      }
    }

    self.synth.addOscillator(oscillator)
  }

  func playNote(frequency: Float) {
    self.synth.playNote(frequency: frequency)
  }

  func connct(to: AVAudioNode, format: AVAudioFormat?) throws {
    try! self.synth.connect(to: self.reverb, format: format)

    self.engine.connect(self.reverb, to: self.delay, format: format)
    self.engine.connect(self.delay, to: to, format: format)
  }
}
