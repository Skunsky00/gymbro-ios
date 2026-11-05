//
//  Gym.swift
//  Gym Bro
//
//  Created by Jacob Johnson on 10/23/26.
//

import Foundation

struct Gym: Codable, Identifiable, Hashable {
    var id: String
    var name: String
    var address: String
    var latitude: Double
    var longitude: Double
    var geohash: String?
}

extension Gym {
    func distanceMiles(to other: Gym) -> Double {
        Geo.distanceMeters(latitude, longitude, other.latitude, other.longitude) / 1609.34
    }
}
