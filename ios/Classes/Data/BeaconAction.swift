//
//  BeaconAction.swift
//  Runner
//
//  Created by Kris Boonefaes on 03/05/2018.
//  Copyright © 2018 The Chromium Authors. All rights reserved.
//

import UIKit
import CoreBluetooth
import CoreLocation

struct BeaconAction: Codable {
    
    let timeStamp: Date
    let beaconUuid: String
    let beaconMajor: Int
    let beaconMinor: Int
    let lastProximity: CLProximity
    
    enum CodingKeys: String, CodingKey {
        case timeStamp = "time_stamp"
        case beaconUuid = "uuid"
        case beaconMajor = "major"
        case beaconMinor = "minor"
        case proximity
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        timeStamp = try container.decode(Date.self, forKey: .timeStamp)
        beaconUuid = try container.decode(String.self, forKey: .beaconUuid)
        beaconMajor = try container.decode(Int.self, forKey: .beaconMajor)
        beaconMinor = try container.decode(Int.self, forKey: .beaconMinor)
        let proximityValue = try container.decode(Int.self, forKey: .proximity)
        lastProximity = CLProximity(rawValue: proximityValue) ?? .unknown
    }
    
    init(with beacon: CLBeacon) {
        timeStamp = Date()
        beaconUuid = beacon.proximityUUID.uuidString
        beaconMajor = beacon.major.intValue
        beaconMinor = beacon.minor.intValue
        lastProximity = beacon.proximity
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(timeStamp, forKey: .timeStamp)
        try container.encode(beaconUuid, forKey: .beaconUuid)
        try container.encode(beaconMajor, forKey: .beaconMajor)
        try container.encode(beaconMinor, forKey: .beaconMinor)
        try container.encode(lastProximity.rawValue, forKey: .proximity)
    }
    
    func fireStoreDict() -> [String: Any] {
        return [CodingKeys.timeStamp.stringValue : Int(timeStamp.timeIntervalSince1970 * 1000),
                CodingKeys.beaconUuid.stringValue : beaconUuid,
                CodingKeys.beaconMajor.stringValue : beaconMajor,
                CodingKeys.beaconMinor.stringValue: beaconMinor,
                CodingKeys.proximity.stringValue : lastProximity.rawValue]
    }
    
    func equals(other: BeaconAction) -> Bool {
        return self.beaconUuid == other.beaconUuid && self.beaconMajor == other.beaconMajor
            && self.beaconMinor == other.beaconMinor && self.lastProximity == other.lastProximity
    }
    
    func represents(beacon: CLBeacon) -> Bool {
        return self.beaconUuid == beacon.proximityUUID.uuidString && self.beaconMajor == beacon.major.intValue && self.beaconMinor == beacon.minor.intValue
    }
    
    static let Formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "hh:mm:ss"
        return formatter
    } ()
    
    internal func description() -> String {
        return "P:\(lastProximity.description) | Mi:\(beaconMinor) | Ma:\(beaconMajor) | \(BeaconAction.Formatter.string(from: timeStamp))"
    }

}

extension CLProximity {
    
    var description: String {
        switch self {
        case .immediate:
            return "Immediate"
        case .near:
            return "Near"
        case .far:
            return "Far"
        case .unknown:
            return "Unknown"
        }
    }
}

