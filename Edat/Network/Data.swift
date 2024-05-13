//
//  File.swift
//  Edat
//
//  Created by Alice Grace on 5/5/24.
//

import Foundation

func postData(
  attitudePitchData: [Double],
  attitudeRollData: [Double],
  attitudeYawData: [Double],

  accelerationXData: [Double],
  accelerationYData: [Double],
  accelerationZData: [Double],

  magneticFieldXData: [Double],
  magneticFieldYData: [Double],
  magneticFieldZData: [Double],

  rotationDataXData: [Double],
  rotationDataYData: [Double],
  rotationDataZData: [Double],

  callback: @escaping (Data?) -> Void
) {
  var req = URLRequest(url: URL(string: "\(EDAT_HTTP_SERVER)/data")!)
  req.allowsCellularAccess = false
  req.httpShouldUsePipelining = true
  req.httpMethod = "POST"
  req.setValue("application/json", forHTTPHeaderField: "Content-Type")
  req.setValue(EDAT_API_SECRET, forHTTPHeaderField: "edat-api-secret")
  req.httpBody = try? JSONEncoder().encode("""
  {
    "timestamp": "\(Date.now.timeIntervalSince1970)",
    "attitude": {
      "pitch": \(attitudePitchData),
      "roll": \(attitudeRollData),
      "yaw": \(attitudeYawData)
    },
    "acceleration": {
      "x": \(accelerationXData),
      "y": \(accelerationYData),
      "z": \(accelerationZData)
    },
    "magneticField": {
      "x": \(magneticFieldXData),
      "y": \(magneticFieldYData),
      "z": \(magneticFieldZData)
    },
    "rotation": {
      "x": \(rotationDataXData),
      "y": \(rotationDataYData),
      "z": \(rotationDataZData)
    }
  }
  """)

  let task: URLSessionDataTask = URLSession.shared.dataTask(with: req) { data, _, err in
    if data != nil, err == nil {
      callback(data)
    } else {
      callback(Data())
    }
  }
  task.resume()
}
