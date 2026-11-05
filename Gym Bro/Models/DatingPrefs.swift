//
//  DatingPrefs.swift
//  Gym Bro
//
//  Created by Jacob Johnson on 11/2/26.
//

import Foundation

struct DatingPrefs {
    var enabled = false
    var interestedIn: Set<Gender> = []
    var minAge = 18
    var maxAge = 99
    var radiusMiles = 5
}

extension Gender {
    var interestTitle: String {
        switch self {
        case .man: return "Men"
        case .woman: return "Women"
        case .nonbinary: return "Nonbinary people"
        }
    }
}
