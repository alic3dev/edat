//
//  DataCollector.swift
//  Edat
//
//  Created by Alice Grace on 5/5/24.
//

import CoreMotion
import Foundation

final class DataCollector {
  private var dataUpdateInterval: Double = 1.0 / 50.0 // 50.0hz
  private var timer: Timer?

  private var attitudePitchData: [Double] = []
  private var attitudeRollData: [Double] = []
  private var attitudeYawData: [Double] = []

  private var accelerationXData: [Double] = []
  private var accelerationYData: [Double] = []
  private var accelerationZData: [Double] = []

  private var magneticFieldXData: [Double] = []
  private var magneticFieldYData: [Double] = []
  private var magneticFieldZData: [Double] = []

  private var rotationDataXData: [Double] = []
  private var rotationDataYData: [Double] = []
  private var rotationDataZData: [Double] = []

  let motion: CMMotionManager = .init()
  let ambientPressure: CMAmbientPressureData = .init()

  var serverData: Data?
  var serverDataLastUpdate: Date = .now

  var shouldPostData: Bool = true

  init() {
    if self.motion.isAccelerometerAvailable {
      self.motion.accelerometerUpdateInterval = self.dataUpdateInterval
      self.motion.startAccelerometerUpdates()
    }

    if self.motion.isGyroAvailable {
      self.motion.gyroUpdateInterval = self.dataUpdateInterval
      self.motion.startGyroUpdates()
    }

    if self.motion.isMagnetometerAvailable {
      self.motion.magnetometerUpdateInterval = self.dataUpdateInterval
      self.motion.startMagnetometerUpdates()
    }

    if self.motion.isDeviceMotionAvailable {
      self.motion.deviceMotionUpdateInterval = self.dataUpdateInterval
      self.motion.startDeviceMotionUpdates(using: .xArbitraryCorrectedZVertical)
    }

    self.startUpdateTimer()
  }

  private func startUpdateTimer() {
    if self.timer != nil {
      self.timer!.invalidate()
    }

    self.timer = Timer(
      fire: Date(),
      interval: self.dataUpdateInterval,
      repeats: true,
      block: { _ in

        self.attitudePitchData.append(self.motion.deviceMotion?.attitude.pitch ?? 0)
        self.attitudeRollData.append(self.motion.deviceMotion?.attitude.roll ?? 0)
        self.attitudeYawData.append(self.motion.deviceMotion?.attitude.yaw ?? 0)

        self.accelerationXData.append(self.motion.accelerometerData?.acceleration.x ?? 0)
        self.accelerationYData.append(self.motion.accelerometerData?.acceleration.y ?? 0)
        self.accelerationZData.append(self.motion.accelerometerData?.acceleration.z ?? 0)

        self.magneticFieldXData.append(self.motion.magnetometerData?.magneticField.x ?? 0)
        self.magneticFieldYData.append(self.motion.magnetometerData?.magneticField.y ?? 0)
        self.magneticFieldZData.append(self.motion.magnetometerData?.magneticField.z ?? 0)

        self.rotationDataXData.append(self.motion.gyroData?.rotationRate.x ?? 0)
        self.rotationDataYData.append(self.motion.gyroData?.rotationRate.y ?? 0)
        self.rotationDataZData.append(self.motion.gyroData?.rotationRate.z ?? 0)

        if self.attitudePitchData.count < 5 {
          return
        }

        if self.shouldPostData {
          postData(
            attitudePitchData: self.attitudePitchData,
            attitudeRollData: self.attitudeRollData,
            attitudeYawData: self.attitudeYawData,

            accelerationXData: self.accelerationXData,
            accelerationYData: self.accelerationYData,
            accelerationZData: self.accelerationZData,

            magneticFieldXData: self.magneticFieldXData,
            magneticFieldYData: self.magneticFieldYData,
            magneticFieldZData: self.magneticFieldZData,

            rotationDataXData: self.rotationDataXData,
            rotationDataYData: self.rotationDataYData,
            rotationDataZData: self.rotationDataZData

          ) { data in
            self.serverDataLastUpdate = Date.now
            self.serverData = data
          }
        }

        self.resetData()
      }
    )
    RunLoop.main.add(self.timer!, forMode: RunLoop.Mode.default)
  }

  private func resetData() {
    self.attitudePitchData = []
    self.attitudeRollData = []
    self.attitudeYawData = []

    self.accelerationXData = []
    self.accelerationYData = []
    self.accelerationZData = []

    self.magneticFieldXData = []
    self.magneticFieldYData = []
    self.magneticFieldZData = []

    self.rotationDataXData = []
    self.rotationDataYData = []
    self.rotationDataZData = []
  }

  func setDataUpdateInterval(dataUpdateInterval: Double) {
    self.dataUpdateInterval = dataUpdateInterval

    self.startUpdateTimer()
  }
}
