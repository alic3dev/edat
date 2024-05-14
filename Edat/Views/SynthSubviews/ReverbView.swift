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
  var index: Int
  var reverb: AVAudioUnitReverb

  var body: some View {
    Section("Reverb \(index + 1) \(reverb.name)") {
//          Picker("Preset", selection: reverb.) {
//            ForEach(Notes, id: \.self.hashValue) { note in
//              Text(getNoteLabel(note: note)).tag(note)
//            }
//          }.onChange(of: self.selectedScaleKey) {
//            UserDefaults.standard.setValue(self.selectedScaleKey.rawValue, forKey: "ScaleKey")
//            self.selectedScaleInKey = getScaleInKey(scale: self.selectedScale, key: self.selectedScaleKey)
//          }

      Slider(value: Binding(
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
