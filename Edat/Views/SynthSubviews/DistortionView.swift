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
  var index: Int
  var distortion: AVAudioUnitDistortion

  var body: some View {
    Section("Distortion \(index + 1) \(distortion.name)") {
      Slider(value: Binding(
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

      Slider(value: Binding(
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
