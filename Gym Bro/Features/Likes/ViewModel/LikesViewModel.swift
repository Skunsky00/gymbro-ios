//
//  LikesViewModel.swift
//  Gym Bro
//
//  Created by Jacob Johnson on 10/30/26.
//

import SwiftUI
import FirebaseFirestore
import Combine

@MainActor
final class LikesViewModel: ObservableObject {
    @Published var items: [IncomingLike] = []      // premium only
    @Published var lockedTrain = 0                 // free only
    @Published var lockedDate = 0
    @Published var filter: ModeFilter = .all
    @Published var isPremium = false
    @Published var hasLoaded = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var newMatch: AppUser?
    @Published var newMatchMode: MatchMode = .train
    @Published var paywallReason: PaywallReason?

    private let service = DiscoverService.shared
    private let userService = UserService.shared
    private let safety = SafetyService.shared
    private var myID: String?

    var visibleItems: [IncomingLike] { items.filter { filter.includes($0.mode) } }

    var visibleLockedCount: Int {
        switch filter {
        case .all: return lockedTrain + lockedDate
        case .train: return lockedTrain
        case .date: return lockedDate
        }
    }

    var hasAnyLikes: Bool { !items.isEmpty || lockedTrain + lockedDate > 0 }

    func load(userID: String) async {
        myID = userID
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let response = try await EntitlementService.shared.fetchReceivedLikes()
            isPremium = response.isPremium

            guard response.isPremium else {
                lockedTrain = response.trainCount
                lockedDate = response.dateCount
                items = []
                hasLoaded = true
                return
            }

            lockedTrain = 0
            lockedDate = 0
            let ids = Array(Set(response.likes.map(\.fromID)))
            let users = try await userService.fetchUsers(ids: ids)
            let byID = Dictionary(users.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
            items = response.likes.compactMap { like in
                guard let user = byID[like.fromID] else { return nil }
                return IncomingLike(senderID: like.fromID, mode: like.mode, user: user,
                                    photoURL: like.photoURL, comment: like.comment,
                                    createdAt: like.createdAt)
            }
            .sorted { $0.createdAt > $1.createdAt }
            hasLoaded = true
        } catch {
            errorMessage = "Couldn't load likes. Check your connection."
            print("likes load error:", error)
        }
    }

    func likeBack(_ item: IncomingLike) async {
        items.removeAll { $0.id == item.id }
        do {
            let result = try await service.sendLike(to: item.senderID, mode: item.mode)
            if result.matched {
                newMatchMode = item.mode
                newMatch = item.user
            }
        } catch {
            restore(item)
            if DiscoverService.isOutOfLikes(error) {
                paywallReason = .unlimitedLikes
            } else {
                errorMessage = "Couldn't send that like. Try again."
            }
            print("like back error:", error)
        }
    }

    func pass(_ item: IncomingLike) async {
        guard let myID else { return }
        items.removeAll { $0.id == item.id }
        do {
            try await service.pass(from: myID, to: item.senderID, mode: item.mode)
        } catch {
            restore(item)
            errorMessage = "Something went wrong. Try again."
        }
    }

    func block(_ item: IncomingLike) async {
        guard let myID else { return }
        items.removeAll { $0.senderID == item.senderID }
        do {
            try await safety.block(item.senderID, by: myID, matchID: nil)
        } catch {
            errorMessage = "Couldn't block. Try again."
        }
    }

    func report(_ item: IncomingLike, reason: ReportReason, details: String, alsoBlock: Bool) async {
        guard let myID else { return }
        items.removeAll { $0.senderID == item.senderID }
        do {
            try await safety.report(reportedID: item.senderID, reporterID: myID,
                                    reason: reason, details: details, matchID: nil)
            if alsoBlock {
                try await safety.block(item.senderID, by: myID, matchID: nil)
            } else {
                try await service.pass(from: myID, to: item.senderID, mode: item.mode)
            }
        } catch {
            errorMessage = "Couldn't send the report. Try again."
        }
    }

    private func restore(_ item: IncomingLike) {
        items.append(item)
        items.sort { $0.createdAt > $1.createdAt }
    }
}
