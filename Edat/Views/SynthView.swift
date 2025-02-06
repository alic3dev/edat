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
  @State var reloadView: Bool = false
  @State private var id: String = UUID().uuidString
  @State var playMode: PlayMode = .device
  
  var synth: Synth

  var body: some View {
    List {
      Section("Settings") {
        TextField("Name", text: Binding<String>(
          get: {
            synth.name
          },
          set: { value in
            synth.name = value
          }
        ))

        Toggle(isOn: Binding<Bool>(
          get: {
            synth.enabled
          },
          set: { enabled in
            synth.enabled = enabled
          }
        )) {
          Text("Enable")
        }
        
        Picker("Playmode", selection: self.$playMode, content: {
          Text("Device").tag(PlayMode.device)
          Text("Sequencer").tag(PlayMode.sequencer)
        }).onChange(of: self.playMode, {
          self.synth.playMode = self.playMode;
        })

        Slider(
          value: Binding<Float>(
            get: {
              synth.mixer.outputVolume
            },
            set: { value in
              synth.mixer.outputVolume = value
            }
          ),
          in: 0 ... 1,
          step: 0.01
        ) {
          Text("Volume")
        } minimumValueLabel: {
          Text("\(Image(systemName: "speaker"))")
        } maximumValueLabel: {
          Text("\(Image(systemName: "speaker.wave.3"))")
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
      
      ForEach(Array(synth.))

      if synth.modifiers.count > 0 {
        Section("Modifiers") {
          ForEach(synth.modifiers) { modifier in
            ModifiersView(modifier: modifier)
          }
        }
      }

      ForEach(Array(synth.effectChain.enumerated()), id: \.offset) { index, effect in
        if effect is AVAudioUnitEQ {
          EQView(index: index, eq: effect as! AVAudioUnitEQ)
        } else if effect is AVAudioUnitDelay {
          DelayView(index: index, delay: effect as! AVAudioUnitDelay)
        } else if effect is AVAudioUnitReverb {
          ReverbView(index: index, reverb: effect as! AVAudioUnitReverb)
        } else if effect is AVAudioUnitDistortion {
          DistortionView(index: index, distortion: effect as! AVAudioUnitDistortion)
        }
      }.id(self.id)

      Button("Add EQ", action: {
        let filter: AVAudioUnitEQ = .init(numberOfBands: 1)

        synth.addEffect(effect: filter)

        self.id = UUID().uuidString
      })
      Button("Add Delay", action: {
        let delay: AVAudioUnitDelay = .init()

        synth.addEffect(effect: delay)

        self.id = UUID().uuidString
      })
      Button("Add Reverb", action: {
        let reverb: AVAudioUnitReverb = .init()

        synth.addEffect(effect: reverb)

        self.id = UUID().uuidString
      })
      Button("Add Distortion", action: {
        let distortion: AVAudioUnitDistortion = .init()

        synth.addEffect(effect: distortion)

        self.id = UUID().uuidString
      })
    }.onAppear(perform: {
      self.playMode = self.synth.playMode;
    })
  }
}
