//
//  Geo.swift
//  Gym Bro
//
//  Created by Jacob Johnson on 10/24/26.
//

import Foundation

enum Geo {
    static func distanceMeters(_ lat1: Double, _ lon1: Double,
                               _ lat2: Double, _ lon2: Double) -> Double {
        let r = 6_371_000.0
        let dLat = (lat2 - lat1) * .pi / 180
        let dLon = (lon2 - lon1) * .pi / 180
        let a = sin(dLat / 2) * sin(dLat / 2)
            + cos(lat1 * .pi / 180) * cos(lat2 * .pi / 180) * sin(dLon / 2) * sin(dLon / 2)
        return r * 2 * atan2(sqrt(a), sqrt(1 - a))
    }
}

enum Geohash {
    private static let base32 = Array("0123456789bcdefghjkmnpqrstuvwxyz")

    static func encode(latitude: Double, longitude: Double, precision: Int) -> String {
        var latRange = (min: -90.0, max: 90.0)
        var lonRange = (min: -180.0, max: 180.0)
        var hash = ""
        var bits = 0
        var value = 0
        var isLongitudeBit = true

        while hash.count < precision {
            if isLongitudeBit {
                let mid = (lonRange.min + lonRange.max) / 2
                if longitude >= mid { value = (value << 1) | 1; lonRange.min = mid }
                else { value = value << 1; lonRange.max = mid }
            } else {
                let mid = (latRange.min + latRange.max) / 2
                if latitude >= mid { value = (value << 1) | 1; latRange.min = mid }
                else { value = value << 1; latRange.max = mid }
            }
            isLongitudeBit.toggle()
            bits += 1
            if bits == 5 {
                hash.append(base32[value])
                bits = 0
                value = 0
            }
        }
        return hash
    }

    /// Size of one cell in degrees at a given precision.
    private static func cellSize(precision: Int) -> (lat: Double, lon: Double) {
        let totalBits = precision * 5
        let lonBits = (totalBits + 1) / 2
        let latBits = totalBits / 2
        return (180.0 / pow(2.0, Double(latBits)), 360.0 / pow(2.0, Double(lonBits)))
    }

    /// Geohash prefixes whose cells cover the bounding box of a circle with the given radius.
    /// Uses the finest precision that needs no more than `maxCells` cells.
    static func coveringPrefixes(latitude: Double, longitude: Double,
                                 radiusMeters: Double, maxCells: Int = 25) -> [String] {
        let metersPerDegree = 111_000.0
        let lonScale = max(cos(latitude * .pi / 180), 0.01)
        let latDelta = radiusMeters / metersPerDegree
        let lonDelta = min(radiusMeters / (metersPerDegree * lonScale), 180)

        let minLat = max(latitude - latDelta, -89.999999)
        let maxLat = min(latitude + latDelta, 89.999999)
        let minLon = longitude - lonDelta
        let maxLon = longitude + lonDelta

        struct Grid {
            let precision: Int
            let size: (lat: Double, lon: Double)
            let rows: ClosedRange<Int>
            let cols: ClosedRange<Int>
            var count: Int { rows.count * cols.count }
        }

        func grid(_ p: Int) -> Grid {
            let size = cellSize(precision: p)
            return Grid(
                precision: p,
                size: size,
                rows: Int(floor((minLat + 90) / size.lat))...Int(floor((maxLat + 90) / size.lat)),
                cols: Int(floor((minLon + 180) / size.lon))...Int(floor((maxLon + 180) / size.lon))
            )
        }

        var chosen = grid(1)
        for p in 1...9 {
            let candidate = grid(p)
            if candidate.count <= maxCells { chosen = candidate } else { break }
        }

        let colCount = Int((360.0 / chosen.size.lon).rounded())
        var prefixes = Set<String>()
        for row in chosen.rows {
            let lat = -90 + (Double(row) + 0.5) * chosen.size.lat
            for col in chosen.cols {
                let wrapped = ((col % colCount) + colCount) % colCount   // handles crossing ±180°
                let lon = -180 + (Double(wrapped) + 0.5) * chosen.size.lon
                prefixes.insert(encode(latitude: lat, longitude: lon, precision: chosen.precision))
            }
        }
        return Array(prefixes)
    }
}
