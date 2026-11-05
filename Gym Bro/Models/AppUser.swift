//
//  AppUser.swift
//  Gym Bro
//
//  Created by Jacob Johnson on 10/23/26.
//

import Foundation

enum TrainWithPreference: String, Codable, CaseIterable {
    case men, women, anyone
}

struct AppUser: Identifiable, Codable {
    let id: String
    var firstName: String = ""
    var birthdate: Date?
    var homeGym: Gym?
    var trainWith: TrainWithPreference?
    var gender: Gender?
    var trainingStyles: [TrainingStyle]?
    var experience: ExperienceLevel?
    var goal: FitnessGoal?
    var lifts: LiftPRs?
    var photoURLs: [String]?
    var onboardingStep: Int = 0
    var onboardingComplete = false
    var availability: [String]?
    var createdAt = Date()
    var prefs: DiscoveryPrefs?
    var caption: String?
    
    nonisolated func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(firstName, forKey: .firstName)
        try c.encodeIfPresent(birthdate, forKey: .birthdate)
        try c.encodeIfPresent(homeGym, forKey: .homeGym)
        try c.encodeIfPresent(trainWith, forKey: .trainWith)
        try c.encodeIfPresent(gender, forKey: .gender)
        try c.encodeIfPresent(trainingStyles, forKey: .trainingStyles)
        try c.encodeIfPresent(experience, forKey: .experience)
        try c.encodeIfPresent(goal, forKey: .goal)
        try c.encodeIfPresent(lifts, forKey: .lifts)
        // photoURLs is intentionally NOT encoded: only the server writes it.
        try c.encode(onboardingStep, forKey: .onboardingStep)
        try c.encode(onboardingComplete, forKey: .onboardingComplete)
        try c.encodeIfPresent(availability, forKey: .availability)
        try c.encode(createdAt, forKey: .createdAt)
        try c.encodeIfPresent(prefs, forKey: .prefs)
    }
}


// add a title to the enum
extension TrainWithPreference {
    var title: String {
        switch self {
        case .men: return "Men"
        case .women: return "Women"
        case .anyone: return "Anyone"
        }
    }
}

enum Gender: String, Codable, CaseIterable {
    case man, woman, nonbinary

    var title: String {
        switch self {
        case .man: return "Man"
        case .woman: return "Woman"
        case .nonbinary: return "Nonbinary"
        }
    }
}


extension TrainWithPreference {
    func accepts(_ gender: Gender?) -> Bool {
        switch self {
        case .anyone: return true
        case .men: return gender == .man
        case .women: return gender == .woman
        }
    }
}

extension AppUser {
    var age: Int? {
        guard let birthdate else { return nil }
        return Calendar.current.dateComponents([.year], from: birthdate, to: Date()).year
    }

    /// Both people's preferences must fit the other person.
    func isCompatible(with other: AppUser) -> Bool {
        (trainWith ?? .anyone).accepts(other.gender)
            && (other.trainWith ?? .anyone).accepts(gender)
    }
}



