//
//  GymSearchService.swift
//  Gym Bro
//
//  Created by Jacob Johnson on 10/23/26.
//

import Foundation
import MapKit
internal import CoreLocation

struct GymSearchService {
    func search(query: String, near coordinate: CLLocationCoordinate2D?) async throws -> [Gym] {
        let request = MKLocalSearch.Request()
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        request.naturalLanguageQuery = trimmed.isEmpty ? "gym" : trimmed
        request.resultTypes = .pointOfInterest
        request.pointOfInterestFilter = MKPointOfInterestFilter(including: [.fitnessCenter])

        if let coordinate {
            request.region = MKCoordinateRegion(center: coordinate,
                                                latitudinalMeters: 20_000,
                                                longitudinalMeters: 20_000)
        }

        let response = try await MKLocalSearch(request: request).start()
        return response.mapItems.map { item in
            let c = item.placemark.coordinate
            return Gym(
                id: String(format: "%.4f_%.4f", c.latitude, c.longitude),
                name: item.name ?? "Gym",
                address: item.placemark.title ?? "",
                latitude: c.latitude,
                longitude: c.longitude,
                geohash: Geohash.encode(latitude: c.latitude, longitude: c.longitude, precision: 9)
            )
        }
    }
}
