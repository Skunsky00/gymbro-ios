//
//  PreferencesViewModel.swift
//  Gym Bro
//
//  Created by Jacob Johnson on 10/24/26.
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class PreferencesViewModel: ObservableObject {
    @Published var trainWith: TrainWithPreference = .anyone
    @Published var minAge = 18
    @Published var maxAge = 99
    @Published var experience: Set<ExperienceLevel> = []
    @Published var requireOverlap = false
    @Published var isLoaded = false
    @Published var isSaving = false
    @Published var errorMessage: String?
    @Published var radiusIndex: Double = 3

    private var user: AppUser?
    
    var radiusMiles: Int {
        DiscoveryPrefs.radiusOptions[Int(radiusIndex.rounded())]
    }
    var radiusLabel: String {
        radiusMiles == 0
            ? "My gym only"
            : "Within \(radiusMiles) mile\(radiusMiles == 1 ? "" : "s") of my gym"
    }

    func load(userID: String) async {
        guard !isLoaded else { return }
        guard let user = try? await UserService.shared.fetchUser(id: userID) else {
            errorMessage = "Couldn't load your preferences."
            return
        }
        self.user = user
        let prefs = user.prefs ?? DiscoveryPrefs()
        trainWith = user.trainWith ?? .anyone
        minAge = prefs.minAge
        maxAge = prefs.maxAge
        experience = Set(prefs.experience)
        requireOverlap = prefs.requireScheduleOverlap
        radiusIndex = Double(DiscoveryPrefs.radiusOptions.firstIndex(of: prefs.radiusMiles ?? 5) ?? 3)
        isLoaded = true
    }

    func toggleExperience(_ level: ExperienceLevel) {
        if experience.contains(level) {
            experience.remove(level)
        } else {
            experience.insert(level)
        }
    }

    func save() async -> Bool {
        guard var user else { return false }
        isSaving = true
        defer { isSaving = false }
        user.trainWith = trainWith
        user.prefs = DiscoveryPrefs(
            minAge: minAge,
            maxAge: maxAge,
            experience: experience.sorted { $0.rawValue < $1.rawValue },
            requireScheduleOverlap: requireOverlap,
            radiusMiles: radiusMiles
        )
        do {
            try UserService.shared.save(user)
            return true
        } catch {
            errorMessage = "Couldn't save. Try again."
            print("save prefs error:", error)
            return false
        }
    }
}
