//
//  PaywallReason.swift
//  Gym Bro
//
//  Created by Jacob Johnson on 10/30/26.
//

import Foundation
import SwiftUI

enum PaywallReason: String, Identifiable {
    case general
    case seeWhoLikesYou
    case unlimitedLikes
    var id: String { rawValue }

    var title: String {
        switch self {
        case .general: return "Spotter+"
        case .seeWhoLikesYou: return "See who likes you"
        case .unlimitedLikes: return "You're out of likes for today"
        }
    }

    var subtitle: String {
        switch self {
        case .general: return "Get the most out of finding your gym partner."
        case .seeWhoLikesYou: return "Subscribe to see everyone who likes you and like them back."
        case .unlimitedLikes: return "Subscribe for unlimited likes, or come back tomorrow for more."
        }
    }
}
