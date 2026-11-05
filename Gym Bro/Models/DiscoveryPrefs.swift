//
//  DiscoveryPrefs.swift
//  Gym Bro
//
//  Created by Jacob Johnson on 10/24/26.
//

import Foundation

struct DiscoveryPrefs: Codable {
    var minAge: Int = 18
    var maxAge: Int = 99
    var experience: [ExperienceLevel] = []   // empty means anyone
    var requireScheduleOverlap = false
    var radiusMiles: Int?

    // Spotter+ filters. All optional so profiles saved before they existed still load.
    var styles: [TrainingStyle]?
    var goals: [FitnessGoal]?
    var minBenchLb: Int?
    var minSquatLb: Int?
    var minDeadliftLb: Int?

    static let radiusOptions = [0, 1, 3, 5, 10, 25, 50]
    static let freeRadiusLimit = 25

    /// Free accounts search up to 25 miles. Spotter+ goes to 50.
    func effectiveRadius(premium: Bool) -> Int {
        let miles = radiusMiles ?? 5
        return premium ? miles : min(miles, Self.freeRadiusLimit)
    }

    func accepts(_ other: AppUser, myAvailability: [String]?, premium: Bool = false) -> Bool {
        if let age = other.age, age < minAge || age > maxAge { return false }
        if !experience.isEmpty, let level = other.experience, !experience.contains(level) {
            return false
        }
        if requireScheduleOverlap,
           ScheduleOverlap.shared(myAvailability, other.availability).isEmpty {
            return false
        }
        guard premium else { return true }   // the filters below are Spotter+ only

        if let styles, !styles.isEmpty {
            let theirs = other.trainingStyles ?? []
            if !theirs.contains(where: { styles.contains($0) }) { return false }
        }
        if let goals, !goals.isEmpty {
            guard let goal = other.goal, goals.contains(goal) else { return false }
        }
        if let minBenchLb, (other.lifts?.benchLb ?? 0) < minBenchLb { return false }
        if let minSquatLb, (other.lifts?.squatLb ?? 0) < minSquatLb { return false }
        if let minDeadliftLb, (other.lifts?.deadliftLb ?? 0) < minDeadliftLb { return false }
        return true
    }
}
