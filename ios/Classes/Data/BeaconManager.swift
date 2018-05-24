//
//  BeaconManager.swift
//  Runner
//
//  Created by Kris Boonefaes on 22/05/2018.
//  Copyright © 2018 The Chromium Authors. All rights reserved.
//

import UIKit
import CoreBluetooth
import CoreLocation

class BeaconManager: NSObject {
    
    static let shared = BeaconManager()
    
    fileprivate let locationManager: CLLocationManager = CLLocationManager()
    fileprivate var cbManager: CBCentralManager?
    fileprivate var monitoredRegions: [MonitoredBeaconRegion] = [MonitoredBeaconRegion]()
    fileprivate var resumeScanning = false
    fileprivate var startScanning  = false
    fileprivate var batterySaverTimer: Timer?
    var batterySaverTimeout: TimeInterval = 30
    
    override init() {
        super.init()
        cbManager = CBCentralManager(delegate: self, queue: nil)
        self.locationManager.delegate = self
    }
    
    func add(region: String, identifier: String, limit: UInt = 0, includeUnknown: Bool = false,  onRanged: ((BeaconAction) -> ())?) throws {
        let newRegion = try MonitoredBeaconRegion(with: region, identifier: identifier, limit: limit, includeUnknown: includeUnknown, onRanged: onRanged)
        if !monitoredRegions.contains(where: { (region) -> Bool in
            return region.equals(other: newRegion)
        }) {
            monitoredRegions.append(newRegion)
        } else {
            throw BeaconError(description: "Already listening for a region with UUID \(newRegion.regionUuid) and identifier \(newRegion.regionIdentifier)")
        }
        startMonitoring(region: newRegion)
    }
    
    func remove(region: String) {
        let regionsToRemove = monitoredRegions.filter { (monitoredRegion) -> Bool in
            return monitoredRegion.regionUuid == region
        }
        monitoredRegions = monitoredRegions.filter { (monitoredRegion) -> Bool in
            return monitoredRegion.regionUuid != region
        }
        regionsToRemove.forEach { (monitoredRegion) in
            stopMonitoring(region: monitoredRegion)
        }
        
    }
    
    func startMonitoring() {
        if ProcessInfo().isOperatingSystemAtLeast(OperatingSystemVersion(majorVersion: 8, minorVersion: 0, patchVersion: 0)) {
            self.locationManager.requestAlwaysAuthorization()
        }
        for monitoredRegion in monitoredRegions {
            self.locationManager.startRangingBeacons(in: monitoredRegion.region)
        }
    }
    
    private func startMonitoring(region: MonitoredBeaconRegion) {
        region.region.notifyEntryStateOnDisplay = true
        region.region.notifyOnEntry = true
        region.region.notifyOnExit = true
        self.locationManager.startRangingBeacons(in: region.region)
    }
    
    private func stopMonitoring(region: MonitoredBeaconRegion) {
        region.region.notifyEntryStateOnDisplay = false
        region.region.notifyOnEntry = false
        region.region.notifyOnExit = false
        self.locationManager.stopRangingBeacons(in: region.region)
    }
    
    @objc func scanWithBatterySavings() {
        for monitoredRegion in monitoredRegions {
            self.locationManager.startRangingBeacons(in: monitoredRegion.region)
        }
    }
    
    func stopScanning() {
        self.batterySaverTimer?.invalidate()
        self.resumeScanning = false
        for monitoredRegion in monitoredRegions {
            self.locationManager.stopMonitoring(for: monitoredRegion.region)
            self.locationManager.stopRangingBeacons(in: monitoredRegion.region)
        }
    }
    
}

// MARK: - CLLocationManagerDelegate
extension BeaconManager: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion) {
        if !beacons.isEmpty {
            var sortedBeacons = beacons.sorted { (beaconA, beaconB) -> Bool in
                if beaconA.proximity.rawValue != beaconB.proximity.rawValue {
                    return beaconA.proximity.rawValue > beaconB.proximity.rawValue
                } else {
                    return beaconA.proximity.rawValue > beaconB.proximity.rawValue && beaconA.accuracy > beaconB.accuracy
                }
            }
            for monitoredRegion in self.monitoredRegions {
                if monitoredRegion.region == region {
                    self.locationManager.stopRangingBeacons(in:region)
                    self.batterySaverTimer = Timer.scheduledTimer(timeInterval:batterySaverTimeout, target: self, selector: #selector(BeaconManager.scanWithBatterySavings), userInfo: nil, repeats: false)
                    
                    if monitoredRegion.limit > 0 {
                        let limit = [UInt(beacons.count), monitoredRegion.limit].min() ?? 0
                        sortedBeacons = Array(beacons.suffix(Int(limit)))
                    }
                    
                    for beacon in sortedBeacons {
                        if beacon.proximity == .unknown && monitoredRegion.includeUnknown {
                            monitoredRegion.didRange?(BeaconAction(with: beacon))
                        } else if beacon.proximity != .unknown {
                            print("beacon: \(beacon.description)")
                            monitoredRegion.didRange?(BeaconAction(with: beacon))
                        }
                    }
                    
                }
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion) {
        if let beaconRegion = region as? CLBeaconRegion {
            if state == CLRegionState.inside {
                self.locationManager.startRangingBeacons(in: beaconRegion)
                self.resumeScanning = true
            } else {
                self.locationManager.stopRangingBeacons(in: beaconRegion)
                self.resumeScanning = false
            }
        }
    }

}

// MARK: - CBCentralManagerDelegate
extension BeaconManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {}
}

class MonitoredBeaconRegion: NSObject, Codable {
    
    let region: CLBeaconRegion
    let regionUuid: String
    let regionIdentifier: String
    let includeUnknown: Bool
    let limit: UInt
    
    var didRange: ((BeaconAction) -> ())?
    
    enum CodingKeys: String, CodingKey {
        case regionUuid = "region_uuid"
        case regionIdentifier = "region_identifier"
        case includeUnknown = "include_unknown"
        case limit
    }
    
    init(with uuid: String, identifier: String, limit: UInt, includeUnknown: Bool, onRanged: ((BeaconAction) -> ())?) throws {
        self.regionUuid = uuid
        self.regionIdentifier = identifier
        self.didRange = onRanged
        guard let uuid = UUID(uuidString: regionUuid) else {
            throw BeaconError(description: "Could not instantiate a monitored region for identifier \(regionIdentifier) because \(regionUuid) is not a valid UUID.")
        }
        self.region = CLBeaconRegion(proximityUUID: uuid, identifier: regionIdentifier)
        self.includeUnknown = includeUnknown
        self.limit = limit
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        regionUuid = try container.decode(String.self, forKey: .regionUuid)
        regionIdentifier = try container.decode(String.self, forKey: .regionIdentifier)
        guard let uuid = UUID(uuidString: regionUuid) else {
            throw BeaconError(description: "Could not instantiate a monitored region for identifier \(regionIdentifier) because \(regionUuid) is not a valid UUID.")
        }
        region = CLBeaconRegion(proximityUUID: uuid, identifier: regionIdentifier)
        includeUnknown = try container.decode(Bool.self, forKey: .includeUnknown)
        limit = try container.decode(UInt.self, forKey: .limit)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(region.proximityUUID.uuidString, forKey: .regionUuid)
        try container.encode(region.identifier, forKey: .regionIdentifier)
        try container.encode(includeUnknown, forKey: .includeUnknown)
        try container.encode(limit, forKey: .limit)
    }
    
    func equals(other: MonitoredBeaconRegion) -> Bool {
        return other.regionUuid == self.regionUuid
    }
    
    static func ==(lhs: MonitoredBeaconRegion, rhs: MonitoredBeaconRegion) -> Bool {
        return lhs.regionUuid == rhs.regionUuid
    }
    
}

struct BeaconError: LocalizedError {
    var localizedDescription: String
    
    init(description: String) {
        self.localizedDescription = description
    }
}
