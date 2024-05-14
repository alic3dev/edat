//
//  EQView.swift
//  Edat
//
//  Created by Alice Grace on 5/14/24.
//

import SwiftUI

import AVFAudio
import Foundation

struct EQView: View {
  var index: Int
  var eq: AVAudioUnitEQ

  var body: some View {
    Section("EQ \(index + 1) \(eq.name)") {
      Slider(value: Binding(
        get: {
          eq.globalGain
        },
        set: { value in
          eq.globalGain = value
        }
      ), in: 0 ... 6, step: 0.1) {
        Text("Global Gain")
      } minimumValueLabel: {
        Text("\(Image(systemName: "speaker"))")
      } maximumValueLabel: {
        Text("\(Image(systemName: "speaker.wave.3"))")
      }

      ForEach(Array(eq.bands.enumerated()), id: \.offset) { index, band in
        EQBandView(filterType: band.filterType, index: index, band: band)
      }
    }
  }
}
