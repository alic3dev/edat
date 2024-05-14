//
//  EQBandView.swift
//  Edat
//
//  Created by Alice Grace on 5/14/24.
//

import SwiftUI

import AVFAudio
import Foundation

let gainEnabledEqFilterTypes: [AVAudioUnitEQFilterType] = [
  .parametric,
  .lowShelf,
  .highShelf,
  .resonantLowShelf,
  .resonantHighShelf
]

let bandwidthEnabledEqFilterTypes: [AVAudioUnitEQFilterType] = [
  .parametric,
  .resonantLowPass,
  .resonantHighPass,
  .bandPass,
  .bandStop,
  .resonantLowShelf,
  .resonantHighShelf
]

struct EQBandView: View {
  @State var filterType: AVAudioUnitEQFilterType

  var index: Int
  var band: AVAudioUnitEQFilterParameters

  var body: some View {
    Text("Band \(index)").font(.title3)

    Toggle(isOn: Binding<Bool>(
      get: {
        band.bypass
      },
      set: { value in
        band.bypass = value

        print(band.filterType.rawValue)
      }
    )) {
      Text("Bypass")
    }

    Picker("Filter Type", selection: $filterType) {
      Text("Parametric").tag(AVAudioUnitEQFilterType.parametric)
      Text("Low Pass").tag(AVAudioUnitEQFilterType.lowPass)
      Text("High Pass").tag(AVAudioUnitEQFilterType.highPass)
      Text("Resonant Low Pass").tag(AVAudioUnitEQFilterType.resonantLowPass)
      Text("Resonant High Pass").tag(AVAudioUnitEQFilterType.resonantHighPass)
      Text("Band Pass").tag(AVAudioUnitEQFilterType.bandPass)
      Text("Band Stop").tag(AVAudioUnitEQFilterType.bandStop)
      Text("Low Shelf Pass").tag(AVAudioUnitEQFilterType.lowShelf)
      Text("High Shelf Pass").tag(AVAudioUnitEQFilterType.highShelf)
      Text("Resonant Low Shelf").tag(AVAudioUnitEQFilterType.resonantLowShelf)
      Text("Resonant High Shelf").tag(AVAudioUnitEQFilterType.resonantHighShelf)
    }.onChange(of: filterType) {
      band.filterType = self.filterType
    }

    Slider(value: Binding(
      get: {
        band.frequency
      },
      set: { value in
        band.frequency = value
      }
    ), in: 20 ... 2000, step: 1) {
      Text("Frequency")
    } minimumValueLabel: {
      Text("\(Image(systemName: "arrow.turn.left.up"))")
    } maximumValueLabel: {
      Text("\(Image(systemName: "arrow.turn.right.up"))")
    }

    Slider(value: Binding<Float>(
      get: {
        band.bandwidth * 100.0
      },
      set: { value in
        band.bandwidth = value / 100.0
      }
    ), in: 5.0 ... 500.0, step: 1.0) {
      Text("Bandwidth")
    } minimumValueLabel: {
      Text("\(Image(systemName: "arrow.right.and.line.vertical.and.arrow.left"))")
    } maximumValueLabel: {
      Text("\(Image(systemName: "arrow.left.and.line.vertical.and.arrow.right"))")
    }.disabled(!bandwidthEnabledEqFilterTypes.contains(where: { $0 == self.filterType }))

    Slider(value: Binding<Float>(
      get: {
        band.gain + 96.0
      },
      set: { value in
        band.gain = value - 96.0
      }
    ), in: 0.0 ... 120.0, step: 0.1) {
      Text("Gain")
    } minimumValueLabel: {
      Text("\(Image(systemName: "speaker"))")
    } maximumValueLabel: {
      Text("\(Image(systemName: "speaker.wave.3"))")
    }.disabled(!gainEnabledEqFilterTypes.contains(where: { $0 == self.filterType }))
  }
}
