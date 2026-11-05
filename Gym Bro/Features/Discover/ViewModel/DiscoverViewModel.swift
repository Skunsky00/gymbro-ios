//
//  DiscoverViewModel.swift
//  Gym Bro
//
//  Created by Jacob Johnson on 10/23/26.
//

import Foundation
import SwiftUI
import Combine
import FirebaseFunctions

@MainActor
final class DiscoverViewModel: ObservableObject {
    @Published var queue: [AppUser] = []
    @Published var me: AppUser?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var needsDatingSetup = false
    @Published var newMatch: AppUser?
    @Published var likesRemaining: Int?       // nil means unlimited or unknown
    @Published var isPremium = false
    @Published var paywallReason: PaywallReason?
    @Published var likeError: String?

    let mode: MatchMode

    private let service = DiscoverService.shared
    private let userService = UserService.shared
    private let safety = SafetyService.shared

    init(mode: MatchMode = .train) {
        self.mode = mode
    }

    var current: AppUser? { queue.first }

    func overlap(with user: AppUser) -> [String] {
        ScheduleOverlap.shared(me?.availability, user.availability)
    }

    func load(userID: String) async {
        isLoading = true
        errorMessage = nil
        needsDatingSetup = false
        defer { isLoading = false }
        do {
            guard let me = try await userService.fetchUser(id: userID),
                  let myGym = me.homeGym else {
                errorMessage = "Finish your profile to see people."
                return
            }
            self.me = me
            if mode == .date {
                queue = try await dateQueue(me: me, myGym: myGym)
            } else {
                queue = try await trainQueue(me: me, myGym: myGym, userID: userID)
            }
        } catch {
            if mode == .date && DatingService.isNotSetUp(error) {
                needsDatingSetup = true
                queue = []
            } else {
                errorMessage = "Couldn't load people. Check your connection."
                print("discover load error (\(mode.rawValue)):", error)
            }
        }
    }

    private func trainQueue(me: AppUser, myGym: Gym, userID: String) async throws -> [AppUser] {
        let prefs = me.prefs ?? DiscoveryPrefs()
        let radius = prefs.effectiveRadius(premium: isPremium)

        async let sameGym = service.fetchCandidates(gymID: myGym.id)
        async let liked = service.fetchLikedIDs(by: userID)
        async let passed = service.fetchPassedIDs(by: userID)
        async let blocked = safety.fetchBlockedIDs(for: userID)

        var all = try await sameGym
        if radius > 0 && myGym.geohash != nil {
            let nearby = try await service.fetchNearby(gym: myGym, radiusMiles: radius)
            let known = Set(all.map(\.id))
            all.append(contentsOf: nearby.filter { !known.contains($0.id) })
        }

        let likedIDs = try await liked
        let passedIDs = try await passed
        let blockedIDs = try await blocked
        let seen = likedIDs.union(passedIDs).union(blockedIDs)

        let filtered = all.filter {
            $0.id != userID
                && !seen.contains($0.id)
                && me.isCompatible(with: $0)
                && prefs.accepts($0, myAvailability: me.availability, premium: isPremium)
        }
        return filtered.sorted {
            sortKey($0, me: me, myGym: myGym) < sortKey($1, me: me, myGym: myGym)
        }
    }

    /// The server already checked both people's preferences and ages, so
    /// all that's left is the distance setting.
    private func dateQueue(me: AppUser, myGym: Gym) async throws -> [AppUser] {
        let datingPrefs = try await DatingService.shared.fetchMyPrefs()
        let radius = isPremium
            ? datingPrefs.radiusMiles
            : min(datingPrefs.radiusMiles, DiscoveryPrefs.freeRadiusLimit)
        let ids = try await DatingService.shared.fetchCandidateIDs(gym: myGym, radiusMiles: radius)
        let users = try await userService.fetchUsers(ids: Array(ids.prefix(60)))
        let nearby = users.filter { user in
            guard let theirGym = user.homeGym else { return false }
            if theirGym.id == myGym.id { return true }
            return radius > 0 && myGym.distanceMiles(to: theirGym) <= Double(radius)
        }
        return nearby.sorted {
            sortKey($0, me: me, myGym: myGym) < sortKey($1, me: me, myGym: myGym)
        }
    }

    /// Same gym first, then more schedule overlap, then closer.
    private func sortKey(_ user: AppUser, me: AppUser, myGym: Gym) -> (Int, Int, Double) {
        let sameGym = user.homeGym?.id == myGym.id ? 0 : 1
        let overlap = ScheduleOverlap.shared(me.availability, user.availability).count
        let miles = user.homeGym.map { myGym.distanceMiles(to: $0) } ?? Double.greatestFiniteMagnitude
        return (sameGym, -overlap, miles)
    }

    func gymNote(for user: AppUser) -> String? {
        guard let myGym = me?.homeGym, let theirGym = user.homeGym else { return nil }
        if theirGym.id == myGym.id { return "Your gym" }
        let miles = myGym.distanceMiles(to: theirGym)
        if miles < 0.1 { return "Next door to your gym" }
        return String(format: "%.1f mi from your gym", miles)
    }

    func pass() async {
        guard let me, let target = queue.first else { return }
        queue.removeFirst()
        do {
            try await service.pass(from: me.id, to: target.id, mode: mode)
        } catch {
            queue.insert(target, at: 0)
            errorMessage = "Something went wrong. Try again."
            print("pass error:", error)
        }
    }

    func block(_ user: AppUser) async {
        guard let me else { return }
        queue.removeAll { $0.id == user.id }
        do {
            try await safety.block(user.id, by: me.id, matchID: nil)
        } catch {
            errorMessage = "Couldn't block. Try again."
            print("block error:", error)
        }
    }

    func report(_ user: AppUser, reason: ReportReason, details: String, alsoBlock: Bool) async {
        guard let me else { return }
        queue.removeAll { $0.id == user.id }
        do {
            try await safety.report(reportedID: user.id, reporterID: me.id,
                                    reason: reason, details: details, matchID: nil)
            if alsoBlock {
                try await safety.block(user.id, by: me.id, matchID: nil)
            } else {
                try await service.pass(from: me.id, to: user.id, mode: mode)
            }
        } catch {
            errorMessage = "Couldn't send the report. Try again."
            print("report error:", error)
        }
    }

    func refreshLikeStatus() async {
        do {
            let status = try await EntitlementService.shared.fetchLikeStatus()
            isPremium = status.isPremium
            likesRemaining = status.remaining
        } catch {
            print("like status error:", error)
        }
    }

    func likePhoto(url: String, comment: String?) async {
        guard let target = queue.first else { return }
        queue.removeFirst()
        do {
            let result = try await service.sendLike(to: target.id, mode: mode,
                                                    photoURL: url, comment: comment)
            likesRemaining = result.remaining
            if result.matched { newMatch = target }
        } catch {
            queue.insert(target, at: 0)
            if DiscoverService.isOutOfLikes(error) {
                likesRemaining = 0
                paywallReason = .unlimitedLikes
            } else {
                let ns = error as NSError
                if ns.domain == FunctionsErrorDomain,
                   ns.code == FunctionsErrorCode.invalidArgument.rawValue {
                    // e.g. "That comment doesn't meet our guidelines."
                    likeError = ns.localizedDescription
                } else {
                    likeError = "Couldn't send that like. Try again."
                }
            }
            print("like photo error:", error)
        }
    }
}
