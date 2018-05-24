//
//  Beacon.swift
//  geolocation
//
//  Created by Kris Boonefaes on 23/05/2018.
//

import UIKit

struct IBeaconResult: Codable{
    let id: Int
    let beacon: BeaconAction
    let result: Bool
}

struct IBeaconUpdatesRequest {
    let id: Int
    let region: MonitoredBeaconRegion
    
    enum CodingKeys: String, CodingKey
    {
        case id
        case region
    }
}

extension IBeaconUpdatesRequest: Decodable {
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(Int.self, forKey: .id)
        region = try values.decode(MonitoredBeaconRegion.self, forKey: .region)
    }
    
}
