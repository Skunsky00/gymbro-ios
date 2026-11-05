//
//  SpotterFiltersViewModel.swift
//  Gym Bro
//
//  Created by Jacob Johnson on 11/2/26.
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class SpotterFiltersViewModel: ObservableObject {
    @Published var styles: Set<TrainingStyle> = []
    @Published var goals: Set<FitnessGoal> = []
    @Published var minBench = 0
    @Published var minSquat = 0
    @Published var minDeadlift = 0
    @Published var isLoaded = false
    @Published var isSaving = false
    @Published var errorMessage: String?

    func load(userID: String) async {
        do {
            let prefs = try await UserService.shared.fetchUser(id: userID)?.prefs
            styles = Set(prefs?.styles ?? [])
            goals = Set(prefs?.goals ?? [])
            minBench = prefs?.minBenchLb ?? 0
            minSquat = prefs?.minSquatLb ?? 0
            minDeadlift = prefs?.minDeadliftLb ?? 0
            isLoaded = true
        } catch {
            errorMessage = "Couldn't load your filters. Check your connection."
            print("filters load error:", error)
        }
    }

    func toggle(_ style: TrainingStyle) {
        if styles.contains(style) { styles.remove(style) } else { styles.insert(style) }
    }

    func toggle(_ goal: FitnessGoal) {
        if goals.contains(goal) { goals.remove(goal) } else { goals.insert(goal) }
    }

    func save(userID: String) async -> Bool {
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }
        do {
            try await UserService.shared.saveAdvancedFilters(
                uid: userID,
                styles: styles.sorted { $0.rawValue < $1.rawValue },
                goals: goals.sorted { $0.rawValue < $1.rawValue },
                minBench: minBench, minSquat: minSquat, minDeadlift: minDeadlift)
            return true
        } catch {
            errorMessage = "Couldn't save. Try again."
            print("filters save error:", error)
            return false
        }
    }
}
