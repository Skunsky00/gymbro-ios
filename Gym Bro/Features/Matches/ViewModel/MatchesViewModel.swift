//
//  MatchesViewModel.swift
//  Gym Bro
//
//  Created by Jacob Johnson on 10/23/26.
//

import SwiftUI
import Combine
import FirebaseFirestore

@MainActor
final class MatchesViewModel: ObservableObject {
    struct Row: Identifiable {
        let match: Match
        let user: AppUser
        var id: String { match.id }
    }

    @Published var rows: [Row] = []
    @Published var isLoading = true
    @Published var myGym: Gym?
    @Published var filter: ModeFilter = .all

    var hasDateMatches: Bool { rows.contains { $0.match.mode == .date } }

    /// Matches nobody has messaged yet, newest first.
    var newRows: [Row] {
        rows
            .filter { $0.match.lastMessage == nil && filter.includes($0.match.mode) }
            .sorted { $0.match.createdAt > $1.match.createdAt }
    }

    /// Matches with at least one message. `rows` is already sorted by latest activity.
    var conversationRows: [Row] {
        rows.filter { $0.match.lastMessage != nil && filter.includes($0.match.mode) }
    }

    private var listener: ListenerRegistration?
    private var userCache: [String: AppUser] = [:]
    private var myID: String?

    func start(userID: String) {
        guard listener == nil else { return }
        myID = userID
        Task { myGym = (try? await UserService.shared.fetchUser(id: userID))?.homeGym }
        listener = MatchService.shared.listenToMatches(for: userID) { [weak self] matches in
            Task { @MainActor in await self?.update(matches) }
        }
    }

    func stop() {
        listener?.remove()
        listener = nil
    }

    private func update(_ matches: [Match]) async {
        guard let myID else { return }
        let sorted = matches
            .filter { $0.endedBy == nil }
            .sorted { ($0.lastMessageAt ?? $0.createdAt) > ($1.lastMessageAt ?? $1.createdAt) }
        var result: [Row] = []
        for match in sorted {
            guard let otherID = match.otherUserID(me: myID) else { continue }
            if userCache[otherID] == nil {
                userCache[otherID] = try? await UserService.shared.fetchUser(id: otherID)
            }
            if let user = userCache[otherID] {
                result.append(Row(match: match, user: user))
            }
        }
        rows = result
        isLoading = false
    }
}
