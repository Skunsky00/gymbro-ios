//
//  ScheduleOverlaps.swift
//  Gym Bro
//
//  Created by Jacob Johnson on 10/23/26.
//

import Foundation

enum ScheduleOverlap {
    /// e.g. ["Mon morning", "Wed evening"], in week order
    static func shared(_ a: [String]?, _ b: [String]?) -> [String] {
        let common = Set(a ?? []).intersection(b ?? [])
        return Day.allCases.flatMap { day in
            TimeWindow.allCases.compactMap { window in
                common.contains(TrainingSlot.key(day, window))
                    ? "\(day.title) \(window.rawValue)" : nil
            }
        }
    }
}
