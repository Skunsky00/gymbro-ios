//
//  TrainingStyle.swift
//  Gym Bro
//
//  Created by Jacob Johnson on 10/23/26.
//

import Foundation

enum TrainingStyle: String, Codable, CaseIterable {
    case bodybuilding, powerlifting, olympicLifting, crossfit
    case calisthenics, running, generalFitness

    var title: String {
        switch self {
        case .bodybuilding: return "Bodybuilding"
        case .powerlifting: return "Powerlifting"
        case .olympicLifting: return "Olympic lifting"
        case .crossfit: return "CrossFit"
        case .calisthenics: return "Calisthenics"
        case .running: return "Running"
        case .generalFitness: return "General fitness"
        }
    }
}
