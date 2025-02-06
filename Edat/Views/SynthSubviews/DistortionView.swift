//
//  DistortionView.swift
//  Edat
//
//  Created by Alice Grace on 5/14/24.
//

import SwiftUI

import AVFAudio
import Foundation

struct DistortionView: View {
  @State var mockPreset: Int = -1

  var index: Int
  var distortion: AVAudioUnitDistortion

  var body: some View {
    Section("Distortion \(index + 1) \(distortion.name)") {
      Picker("Load Factory Preset", selection: self.$mockPreset) {
        Text("").tag(-1)
        Text("Drums Bit Brush").tag(AVAudioUnitDistortionPreset.drumsBitBrush.rawValue)
        Text("Drums Buffer Beats").tag(AVAudioUnitDistortionPreset.drumsBufferBeats.rawValue)
        Text("Drums LoFi").tag(AVAudioUnitDistortionPreset.drumsLoFi.rawValue)
        Text("Multi Broken Speaker").tag(AVAudioUnitDistortionPreset.multiBrokenSpeaker.rawValue)
        Text("Multi Cellphone Concert").tag(AVAudioUnitDistortionPreset.multiCellphoneConcert.rawValue)
        Text("Multi Decimated 1").tag(AVAudioUnitDistortionPreset.multiDecimated1.rawValue)
        Text("Multi Decimated 2").tag(AVAudioUnitDistortionPreset.multiDecimated2.rawValue)
        Text("Multi Decimated 3").tag(AVAudioUnitDistortionPreset.multiDecimated3.rawValue)
        Text("Multi Decimated 4").tag(AVAudioUnitDistortionPreset.multiDecimated4.rawValue)
        Text("Multi Distorted Cubed").tag(AVAudioUnitDistortionPreset.multiDistortedCubed.rawValue)
        Text("Multi Distorted Funk").tag(AVAudioUnitDistortionPreset.multiDistortedFunk.rawValue)
        Text("Multi Distorted Squared").tag(AVAudioUnitDistortionPreset.multiDistortedSquared.rawValue)
        Text("Multi Echo 1").tag(AVAudioUnitDistortionPreset.multiEcho1.rawValue)
        Text("Multi Echo 2").tag(AVAudioUnitDistortionPreset.multiEcho2.rawValue)
        Text("Multi Echo Tight 1").tag(AVAudioUnitDistortionPreset.multiEchoTight1.rawValue)
        Text("Multi Echo Tight 2").tag(AVAudioUnitDistortionPreset.multiEchoTight2.rawValue)
        Text("Multi Everything is Broken").tag(AVAudioUnitDistortionPreset.multiEverythingIsBroken.rawValue)
        Text("Speech Alien Chatter").tag(AVAudioUnitDistortionPreset.speechAlienChatter.rawValue)
        Text("Speech Cosmic Interference").tag(AVAudioUnitDistortionPreset.speechCosmicInterference.rawValue)
        Text("Speech Golden Pi").tag(AVAudioUnitDistortionPreset.speechGoldenPi.rawValue)
        Text("Speech Radio Tower").tag(AVAudioUnitDistortionPreset.speechRadioTower.rawValue)
        Text("Speech Waves").tag(AVAudioUnitDistortionPreset.speechWaves.rawValue)
      }.onChange(of: self.mockPreset) {
        if self.mockPreset != -1 {
          self.distortion.loadFactoryPreset(AVAudioUnitDistortionPreset(rawValue: self.mockPreset)!)
          self.mockPreset = -1
        }
      }

      Slider(value: Binding<Float>(
        get: {
          distortion.preGain
        },
        set: { value in
          distortion.preGain = value
        }
      ), in: 0 ... 6, step: 0.1) {
        Text("Pre-Gain")
      } minimumValueLabel: {
        Text("\(Image(systemName: "speaker"))")
      } maximumValueLabel: {
        Text("\(Image(systemName: "speaker.wave.3"))")
      }

      Slider(value: Binding<Float>(
        get: {
          distortion.wetDryMix
        },
        set: { value in
          distortion.wetDryMix = value
        }
      ), in: 0 ... 100, step: 1) {
        Text("Wet/Dry Mix")
      } minimumValueLabel: {
        Text("\(Image(systemName: "drop"))")
      } maximumValueLabel: {
        Text("\(Image(systemName: "drop.fill"))")
      }
    }
  }
}
