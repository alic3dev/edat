//
//  ModifierView.swift
//  Edat
//
//  Created by Alice Grace on 5/14/24.
//

import SwiftUI

import Foundation

import zer0_ios

struct ModifiersView: View {
  @State var modifier: SynthModifier

  var body: some View {
    Slider(value: Binding<Float>(
      get: {
        modifier.value
      },
      set: { value in
        modifier.value = value
      }
    ), in: modifier.valueMin ... modifier.valueMax, step: (modifier.valueMax - modifier.valueMin) / 1000.0) {
      Text(modifier.name)
    } minimumValueLabel: {
      Text("\(Image(systemName: modifier.iconMin))")
    } maximumValueLabel: {
      Text("\(Image(systemName: modifier.iconMax))")
    }
  }
}
