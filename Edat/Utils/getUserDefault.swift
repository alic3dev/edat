//
//  getUserDefault.swift
//  Edat
//
//  Created by Alice Grace on 5/13/24.
//

import Foundation

func getUserDefault(key: String, defaultValue: Bool) -> Bool {
  return UserDefaults.standard.object(forKey: key) == nil
    ? defaultValue
    : UserDefaults.standard.bool(forKey: key)
}

func getUserDefault(key: String, defaultValue: Float) -> Float {
  return UserDefaults.standard.object(forKey: key) == nil
    ? defaultValue
    : UserDefaults.standard.float(forKey: key)
}

func getUserDefault(key: String, defaultValue: Int) -> Int {
  return UserDefaults.standard.object(forKey: key) == nil
    ? defaultValue
    : UserDefaults.standard.integer(forKey: key)
}

func getUserDefault(key: String, defaultValue: String) -> String {
  return UserDefaults.standard.string(forKey: key) ?? defaultValue
}
