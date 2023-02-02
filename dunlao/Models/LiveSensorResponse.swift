// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
//   let welcome = try? newJSONDecoder().decode(Welcome.self, from: jsonData)

import Foundation

// MARK: - Welcome
struct Welcome: Codable {
    var status: Status
    var sensorList: [SensorList]
}

// MARK: - SensorList
struct SensorList: Codable {
    var sensorLocationID, sensorID, cityID: Int
    var sensorType: SensorTypeClass
    var sensorGPSPosition: SensorGPSPosition
    var sensorExtraInformation: SensorExtraInformation
    var sensorStatus: SensorStatus
}

// MARK: - SensorExtraInformation
struct SensorExtraInformation: Codable {
    var title: String
    var notes: Notes
    var zoneID: Int
}

enum Notes: String, Codable {
    case edenderryParking = "Edenderry parking"
    case empty = ""
    case notes = " "
}

// MARK: - SensorGPSPosition
struct SensorGPSPosition: Codable {
    var latititude, longitude: Double
}

// MARK: - SensorStatus
struct SensorStatus: Codable {
    var isOnline, isOccupied: Bool
    var lastChangedState: String
}

// MARK: - SensorTypeClass
struct SensorTypeClass: Codable {
    var sensorTypeID: Int
    var sensorType: SensorTypeEnum
}

enum SensorTypeEnum: String, Codable {
    case accessible = "Accessible"
    case sensorTypeAccessible = "Accessible "
}

// MARK: - Status
struct Status: Codable {
    var rc: Int
    var response: String
    var success: Bool
}
