//
//  MatchMode.swift
//  Gym Bro
//
//  Created by Jacob Johnson on 11/2/26.
//

import Foundation

enum MatchMode: String, Codable, CaseIterable {
    case train, date

    var title: String {
        switch self {
        case .train: return "Train"
        case .date: return "Date"
        }
    }
}

enum ModeFilter: String, CaseIterable, Identifiable {
    case all, train, date
    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: return "All"
        case .train: return "Train"
        case .date: return "Date"
        }
    }

    func includes(_ mode: MatchMode) -> Bool {
        switch self {
        case .all: return true
        case .train: return mode == .train
        case .date: return mode == .date
        }
    }
}
