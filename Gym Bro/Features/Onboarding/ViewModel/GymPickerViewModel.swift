//
//  GymPickerViewModel.swift
//  Gym Bro
//
//  Created by Jacob Johnson on 10/23/26.
//

import Foundation
import SwiftUI
internal import CoreLocation
import Combine

@MainActor
final class GymPickerViewModel: ObservableObject {
    @Published var query = ""
    @Published var results: [Gym] = []
    @Published var isSearching = false
    @Published var errorMessage: String?

    private(set) var userLocation: CLLocation?
    private let searchService = GymSearchService()
    private var searchTask: Task<Void, Never>?

    func updateLocation(_ location: CLLocation) {
        userLocation = location
        scheduleSearch(immediately: true)
    }

    func scheduleSearch(immediately: Bool = false) {
        searchTask?.cancel()
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        // Without location, only search once the user types something
        guard userLocation != nil || !trimmed.isEmpty else {
            results = []
            return
        }
        searchTask = Task {
            if !immediately {
                try? await Task.sleep(for: .milliseconds(400))
            }
            guard !Task.isCancelled else { return }
            await performSearch()
        }
    }

    func distanceMiles(to gym: Gym) -> Double? {
        guard let userLocation else { return nil }
        let gymLocation = CLLocation(latitude: gym.latitude, longitude: gym.longitude)
        return userLocation.distance(from: gymLocation) / 1609.34
    }

    private func performSearch() async {
        isSearching = true
        errorMessage = nil
        defer { isSearching = false }
        do {
            let gyms = try await searchService.search(query: query,
                                                      near: userLocation?.coordinate)
            guard !Task.isCancelled else { return }
            results = gyms.sorted {
                (distanceMiles(to: $0) ?? .greatestFiniteMagnitude) <
                (distanceMiles(to: $1) ?? .greatestFiniteMagnitude)
            }
        } catch {
            guard !Task.isCancelled else { return }
            errorMessage = "Couldn't search for gyms. Try again."
            print("gym search error:", error)
        }
    }
}
