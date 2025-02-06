//
//  InitialValues.swift
//  Edat
//
//  Created by Alice Grace on 5/13/24.
//

import Foundation

import zer0_ios

var _initialBPM: Float?
func getInitialBPM() -> Float {
  if _initialBPM != nil {
    return _initialBPM!
  }

  _initialBPM = getUserDefault(key: "BPM", defaultValue: 90.0)

  return _initialBPM!
}

var _initialSelectedScaleKey: Note?
func getInitialSelectedScaleKey() -> Note {
  if _initialSelectedScaleKey != nil {
    return _initialSelectedScaleKey!
  }

  _initialSelectedScaleKey = .init(rawValue: getUserDefault(key: "ScaleKey", defaultValue: Note.C.rawValue)) ?? .C

  return _initialSelectedScaleKey!
}

var _initialSelectedScale: Scale?
func getInitialSelectedScale() -> Scale {
  if _initialSelectedScale != nil {
    return _initialSelectedScale!
  }

  _initialSelectedScale = Scales.first { scale in
    scale.name == getUserDefault(key: "Scale", defaultValue: ScaleMinor.name)
  } ?? ScaleMinor

  return _initialSelectedScale!
}
