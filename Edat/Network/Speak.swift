//
//  Speak.swift
//  Edat
//
//  Created by Alice Grace on 5/6/24.
//

import Foundation

func postSpeak(
  callback: @escaping (String?) -> Void
) {
  var req = URLRequest(url: URL(string: "\(EDAT_HTTP_SERVER)/speak")!)
  req.allowsCellularAccess = false
  req.httpMethod = "POST"
  req.setValue("application/json", forHTTPHeaderField: "Content-Type")
  req.setValue(EDAT_API_SECRET, forHTTPHeaderField: "edat-api-secret")
  req.httpBody = try? JSONEncoder().encode("")

  let task: URLSessionDataTask = URLSession.shared.dataTask(with: req) { data, _, _ in
    if data != nil {
      callback(String(decoding: data!, as: UTF8.self))
    } else {
      callback(nil)
    }
  }
  task.resume()
}
