//
//  DatingPreferencesViewModel.swift
//  Gym Bro
//
//  Created by Jacob Johnson on 11/2/26.
//

import SwiftUI
import Combine

@MainActor
final class DatingPreferencesViewModel: ObservableObject {
    @Published var interestedIn: Set<Gender> = []
    @Published var minAge = 18
    @Published var maxAge = 99
    @Published var radiusIndex: Double = 3          // 5 miles
    @Published var isEnabled = false
    @Published var hasSetUp = false
    @Published var isLoading = true
    @Published var isSaving = false
    @Published var errorMessage: String?

    private let service = DatingService.shared

    var canSave: Bool { !interestedIn.isEmpty && !isSaving }

    var radiusLabel: String {
        let miles = DiscoveryPrefs.radiusOptions[safeIndex]
        if miles == 0 { return "My gym only" }
        return miles == 1 ? "Within 1 mile of my gym" : "Within \(miles) miles of my gym"
    }

    private var safeIndex: Int {
        min(max(Int(radiusIndex), 0), DiscoveryPrefs.radiusOptions.count - 1)
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let prefs = try await service.fetchMyPrefs()
            interestedIn = prefs.interestedIn
            minAge = prefs.minAge
            maxAge = prefs.maxAge
            radiusIndex = Double(DiscoveryPrefs.radiusOptions.firstIndex(of: prefs.radiusMiles) ?? 3)
            isEnabled = prefs.enabled
            hasSetUp = !prefs.interestedIn.isEmpty
        } catch {
            errorMessage = DatingService.message(for: error)
        }
    }

    func toggle(_ gender: Gender) {
        if interestedIn.contains(gender) { interestedIn.remove(gender) }
        else { interestedIn.insert(gender) }
    }

    func save() async -> Bool {
        guard !interestedIn.isEmpty else {
            errorMessage = "Pick at least one option."
            return false
        }
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }
        var prefs = DatingPrefs()
        prefs.enabled = isEnabled
        prefs.interestedIn = interestedIn
        prefs.minAge = minAge
        prefs.maxAge = maxAge
        prefs.radiusMiles = DiscoveryPrefs.radiusOptions[safeIndex]
        do {
            try await service.save(prefs)
            return true
        } catch {
            errorMessage = DatingService.message(for: error)
            return false
        }
    }
}
