//
//  ReverbView.swift
//  Edat
//
//  Created by Alice Grace on 5/14/24.
//

import SwiftUI

import AVFAudio
import Foundation

struct ReverbView: View {
  @State var mockPreset: Int = -1

  var index: Int
  var reverb: AVAudioUnitReverb

  var body: some View {
    Section("Reverb \(index + 1) \(reverb.name)") {
      Picker("Load Factory Preset", selection: self.$mockPreset) {
        Text("").tag(-1)
        Text("Cathedral").tag(AVAudioUnitReverbPreset.cathedral.rawValue)
        Text("Large Chamber").tag(AVAudioUnitReverbPreset.largeChamber.rawValue)
        Text("Large Hall").tag(AVAudioUnitReverbPreset.largeHall.rawValue)
        Text("Large Hall 2").tag(AVAudioUnitReverbPreset.largeHall2.rawValue)
        Text("Large Room").tag(AVAudioUnitReverbPreset.largeRoom.rawValue)
        Text("Large Room 2").tag(AVAudioUnitReverbPreset.largeRoom2.rawValue)
        Text("Medium Chamber").tag(AVAudioUnitReverbPreset.mediumChamber.rawValue)
        Text("Medium Hall").tag(AVAudioUnitReverbPreset.mediumHall.rawValue)
        Text("Medium Hall 2").tag(AVAudioUnitReverbPreset.mediumHall2.rawValue)
        Text("Medium Hall 3").tag(AVAudioUnitReverbPreset.mediumHall3.rawValue)
        Text("Medium Room").tag(AVAudioUnitReverbPreset.mediumRoom.rawValue)
        Text("Plate").tag(AVAudioUnitReverbPreset.plate.rawValue)
        Text("Small Room").tag(AVAudioUnitReverbPreset.smallRoom.rawValue)
      }.onChange(of: self.mockPreset) {
        if self.mockPreset != -1 {
          self.reverb.loadFactoryPreset(AVAudioUnitReverbPreset(rawValue: self.mockPreset)!)
          self.mockPreset = -1
        }
      }

      Slider(value: Binding<Float>(
        get: {
          reverb.wetDryMix
        },
        set: { value in
          reverb.wetDryMix = value
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
