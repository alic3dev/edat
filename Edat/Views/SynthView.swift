//
//  SynthView.swift
//  Edat
//
//  Created by Alice Grace on 5/13/24.
//

import SwiftUI

import AVFAudio
import Foundation

import zer0_ios

struct SynthView: View {
  var synth: Synth

  var body: some View {
    List {
      Section("Settings") {
        Text(synth.name)

        Toggle(isOn: Binding(
          get: {
            synth.enabled
          },
          set: { enabled in
            synth.enabled = enabled
          }
        )) {
          Text("Enable")
        }
      }

      Section("ADSR") {
        Slider(value: Binding<Float>(
          get: {
            synth.attack
          },
          set: { value in
            synth.attack = value
          }
        ), in: 0.0 ... 15.0, step: 0.01) {
          Text("Attack")
        } minimumValueLabel: {
          Text("\(Image(systemName: "hare"))")
        } maximumValueLabel: {
          Text("\(Image(systemName: "tortoise"))")
        }

        Slider(value: Binding<Float>(
          get: {
            synth.decay
          },
          set: { value in
            synth.decay = value
          }
        ), in: 0.0 ... 15.0, step: 0.01) {
          Text("Decay")
        } minimumValueLabel: {
          Text("\(Image(systemName: "figure.fall"))")
        } maximumValueLabel: {
          Text("\(Image(systemName: "figure.stand"))")
        }

        Slider(value: Binding<Float>(
          get: {
            synth.sustain
          },
          set: { value in
            synth.sustain = value
          }
        ), in: 0.0 ... 1.0, step: 0.01) {
          Text("Sustain")
        } minimumValueLabel: {
          Text("\(Image(systemName: "level"))")
        } maximumValueLabel: {
          Text("\(Image(systemName: "level.fill"))")
        }

        Slider(value: Binding<Float>(
          get: {
            synth.sustainDuration
          },
          set: { value in
            synth.sustainDuration = value
          }
        ), in: 0.0 ... 15.0, step: 0.01) {
          Text("Sustain Duration")
        } minimumValueLabel: {
          Text("\(Image(systemName: "chart.line.downtrend.xyaxis"))")
        } maximumValueLabel: {
          Text("\(Image(systemName: "chart.line.flattrend.xyaxis"))")
        }

        Slider(value: Binding<Float>(
          get: {
            synth.release
          },
          set: { value in
            synth.release = value
          }
        ), in: 0.0 ... 15.0, step: 0.01) {
          Text("Release")
        } minimumValueLabel: {
          Text("\(Image(systemName: "cloud.bolt.rain"))")
        } maximumValueLabel: {
          Text("\(Image(systemName: "cloud.rain"))")
        }
      }

      if synth.modifiers.count > 0 {
        Section("Modifiers") {
          ForEach(synth.modifiers) { modifier in
            ModifiersView(modifier: modifier)
          }
        }
      }

      ForEach(Array(synth.eqs.enumerated()), id: \.offset) { index, eq in
        EQView(index: index, eq: eq)
      }

      ForEach(Array(synth.delays.enumerated()), id: \.offset) { index, delay in
        DelayView(index: index, delay: delay)
      }

      ForEach(Array(synth.reverbs.enumerated()), id: \.offset) { index, reverb in
        ReverbView(index: index, reverb: reverb)
      }

      ForEach(Array(synth.distortions.enumerated()), id: \.offset) { index, distortion in
        DistortionView(index: index, distortion: distortion)
      }
    }
  }
}
