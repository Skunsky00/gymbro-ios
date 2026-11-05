//
//  AppRouter.swift
//  Gym Bro
//
//  Created by Jacob Johnson on 10/24/26.
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class AppRouter: ObservableObject {
    static let shared = AppRouter()

    enum Tab: Hashable { case discover, likes, matches, profile }

    @Published var selectedTab: Tab = .discover
    /// Set when a push is tapped; the Matches tab opens this chat.
    @Published var pendingMatchID: String?
    /// The chat currently on screen, so its banners can be skipped.
    var activeChatMatchID: String?

    func openMatches(matchID: String? = nil) {
        pendingMatchID = matchID
        selectedTab = .matches
    }
}
