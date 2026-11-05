//
//  FitnessGoal.swift
//  Gym Bro
//
//  Created by Jacob Johnson on 10/23/26.
//

import Foundation

enum FitnessGoal: String, Codable, CaseIterable {
    case buildMuscle, loseFat, getStronger, stayInShape

    var title: String {
        switch self {
        case .buildMuscle: return "Build muscle"
        case .loseFat: return "Lose fat"
        case .getStronger: return "Get stronger"
        case .stayInShape: return "Stay in shape"
        }
    }

    var subtitle: String {
        switch self {
        case .buildMuscle: return "Bulking"
        case .loseFat: return "Cutting"
        case .getStronger: return "Chasing PRs"
        case .stayInShape: return "Staying consistent"
        }
    }
}
