//
//  SequencerView.swift
//  Edat
//
//  Created by Alice Grace on 10/26/24.
//

import SwiftUI

import zer0_ios

struct SequencerView: View {
  @State var selectedSynth: Int = 0
  @State var octave: Int = 2
  @State var mockPlayMode: PlayMode = .device

  var rows: Int = 10
  var columns: Int = 4

  var synths: [Synth]
  var sequences: [UUID: Sequence]
  var noteTable: [[Float]]
  var noteTableSize: Int
  var scale: Scale

  var beatSignal: Bool

  var body: some View {
    VStack {
      // FIXME: This is for some reason really big lol
      //        Should be standard size but isn't.
      List {
        Section("Options") {
          Picker("Synth", selection: self.$selectedSynth) {
            ForEach(Array(self.synths.enumerated()), id: \.offset) { index, synth in
              Text(synth.name).tag(index)
            }
          }

          Picker("Playmode", selection: self.$mockPlayMode, content: {
            Text("Device").tag(PlayMode.device)
            Text("Sequencer").tag(PlayMode.sequencer)
          }).onChange(of: self.mockPlayMode) {
            self.synths[self.selectedSynth].playMode = self.mockPlayMode
          }
        }
      }

      ScrollView(.vertical, showsIndicators: false) {
        Grid(alignment: .center) {
          ForEach(1 ... 8, id: \.self) { _ in
            GridRow(alignment: .center) {
              ForEach(1 ... self.synths[self.selectedSynth].getPolyphony(), id: \.self) { _ in
                Stepper {
                  Text("Make this some value")
                } onIncrement: {
                  // TODO: Implement
                } onDecrement: {
                  // TODO: Implement
                }

                Stepper(value: Binding<Int>(
                  get: {
                    5
                  },
                  set: { _ in
                    // TODO: Set value here
                  }),
                in: 1 ... 10, step: 1) {
                  Text("Make this some value")
                }
              }
            }
          }
        }
      }
    }.onAppear(perform: {
      self.mockPlayMode = self.synths[self.selectedSynth].playMode
    }).onChange(of: beatSignal) {
      // TODO: Remember to check this - For beat highlighting.
      print(self.beatSignal)
    }
  }
}
