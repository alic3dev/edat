//
//  SynthSpark.swift
//  Edat
//
//  Created by Alice Grace on 5/13/24.
//

import Foundation

import AVFAudio
import zer0_ios

final class SynthSpark: Synth {
  private let engine: AVAudioEngine
  private let sampleRate: Float

  init(engine: AVAudioEngine, sampleRate: Float, volume: Float = 1.0) {
    self.engine = engine
    self.sampleRate = sampleRate

    super.init(engine: self.engine, sampleRate: self.sampleRate, volume: volume, polyphony: 6)

    self.name = "Spark Synth"

    self.attack = 0.1 * 60
    self.decay = 0.03333333333 * 60
    self.sustain = 0.5
    self.sustainDuration = 0.01666666667 * 60
    self.release = 0.01666666667 * 60

    let filter: AVAudioUnitEQ = .init(numberOfBands: 1)
    filter.bands[0].filterType = .lowPass
    filter.bands[0].frequency = 400
    filter.bands[0].bypass = false
    filter.bands[0].gain = 0
    filter.bands[0].bandwidth = 1
    self.addEffect(effect: filter)

    let delay: AVAudioUnitDelay = .init()
    delay.delayTime = 1
    delay.feedback = 30
    delay.lowPassCutoff = 1400
    delay.wetDryMix = 25
    self.addEffect(effect: delay)

    let reverb: AVAudioUnitReverb = .init()
    reverb.loadFactoryPreset(.smallRoom)
    reverb.wetDryMix = 20
    self.addEffect(effect: reverb)
  }

  override func start(onRender: @escaping onSynthRenderFunc) {
    super.start(onRender: onRender)

    let oscillator: Oscillator = .init(engine: self.engine, sampleRate: self.sampleRate, type: .sine, amplitude: 0.6)
    oscillator.start()

    super.addOscillator(oscillator)
  }
}
