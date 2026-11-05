//
//  ExperienceLevel.swift
//  Gym Bro
//
//  Created by Jacob Johnson on 10/23/26.
//

import Foundation

enum ExperienceLevel: String, Codable, CaseIterable {
    case beginner, intermediate, advanced, veteran

    var title: String {
        switch self {
        case .beginner: return "Beginner"
        case .intermediate: return "Intermediate"
        case .advanced: return "Advanced"
        case .veteran: return "Veteran"
        }
    }

    var subtitle: String {
        switch self {
        case .beginner: return "Under 1 year"
        case .intermediate: return "1–3 years"
        case .advanced: return "3–5 years"
        case .veteran: return "5+ years"
        }
    }
}
