//
//  TrainingSchedule.swift
//  Gym Bro
//
//  Created by Jacob Johnson on 10/23/26.
//

import Foundation

enum Day: String, CaseIterable {
    case mon, tue, wed, thu, fri, sat, sun
    var title: String { rawValue.capitalized }
}

enum TimeWindow: String, CaseIterable {
    case morning, afternoon, evening
    var title: String { rawValue.capitalized }
    var hours: String {
        switch self {
        case .morning: return "5–11am"
        case .afternoon: return "11am–4pm"
        case .evening: return "4–10pm"
        }
    }
}

enum TrainingSlot {
    /// e.g. "mon_morning". Stored as plain strings so Firestore can query them.
    static func key(_ day: Day, _ window: TimeWindow) -> String {
        "\(day.rawValue)_\(window.rawValue)"
    }
}
