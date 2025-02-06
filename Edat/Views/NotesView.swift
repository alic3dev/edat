//
//  NotesView.swift
//  Edat
//
//  Created by Alice Grace on 6/8/24.
//

import SwiftUI

import zer0_ios

struct NoteButton: View {
  let action: () -> Void
  let color: Color

  var body: some View {
    Button(action: action) {
      Text("").frame(width: 50, height: 50).padding(0)
    }.padding(0).buttonStyle(.borderedProminent).tint(color)
  }
}

struct NotesView: View {
  @State var selectedSynth: Int = 0
  @State var octave: Int = 2

  var rows: Int = 10
  var columns: Int = 4

  var synths: [Synth]
  var noteTable: [[Float]]
  var scale: Scale

  private func getPlayNote(index: Int) -> () -> Void {
    return {
      let frequency: Float = self.noteTable[
        self.octave + Int(floor(Double(index) / Double(self.scale.notes.count)))
      ][self.scale.notes[index % self.scale.notes.count]]

      self.synths[self.selectedSynth].playNote(frequency: frequency)
    }
  }

  var body: some View {
    VStack {
      Section("Options") {
        Picker("Synth", selection: self.$selectedSynth) {
          ForEach(Array(self.synths.enumerated()), id: \.offset) { index, synth in
            Text(synth.name).tag(index)
          }
        }
      }

      ScrollView(.vertical, showsIndicators: false) {
        Grid(alignment: .center) {
          ForEach(1 ... self.rows, id: \.self) { x in
            GridRow(alignment: .center) {
              ForEach(1 ... self.columns, id: \.self) { y in
                let currentIndex: Int = ((x - 1) * self.columns) + (y - 1)
                let progress = Double(currentIndex) / (Double(rows * self.columns) - 1.0)

                NoteButton(
                  action: self.getPlayNote(index: currentIndex),
                  color: Color(hue: progress, saturation: 0.66, brightness: 1)
                )
              }
            }
          }
        }
      }.defaultScrollAnchor(.center)
    }
  }
}
