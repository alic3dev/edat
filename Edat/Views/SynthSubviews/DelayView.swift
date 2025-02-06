//
//  DelayView.swift
//  Edat
//
//  Created by Alice Grace on 5/14/24.
//

import SwiftUI

import AVFAudio
import Foundation

struct DelayView: View {
  var index: Int
  var delay: AVAudioUnitDelay

  var body: some View {
    Section("Delay \(index + 1) \(delay.name)") {
      Slider(value: Binding<Double>(
        get: {
          delay.delayTime
        },
        set: { value in
          delay.delayTime = value
        }
      ), in: 0 ... 10, step: 0.01) {
        Text("Delay Time")
      } minimumValueLabel: {
        Text("\(Image(systemName: "hourglass.bottomhalf.filled"))")
      } maximumValueLabel: {
        Text("\(Image(systemName: "hourglass.tophalf.filled"))")
      }

      Slider(value: Binding<Float>(
        get: {
          delay.lowPassCutoff
        },
        set: { value in
          delay.lowPassCutoff = value
        }
      ), in: 0 ... 2000, step: 1) {
        Text("Low Pass Cutoff")
      } minimumValueLabel: {
        Text("\(Image(systemName: "dial.low"))")
      } maximumValueLabel: {
        Text("\(Image(systemName: "dial.low.fill"))")
      }

      Slider(value: Binding<Float>(
        get: {
          delay.feedback
        },
        set: { value in
          delay.feedback = value
        }
      ), in: 0 ... 100, step: 1) {
        Text("Feedback")
      } minimumValueLabel: {
        Text("\(Image(systemName: "point.forward.to.point.capsulepath"))")
      } maximumValueLabel: {
        Text("\(Image(systemName: "point.forward.to.point.capsulepath.fill"))")
      }

      Slider(value: Binding<Float>(
        get: {
          delay.wetDryMix
        },
        set: { value in
          delay.wetDryMix = value
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
