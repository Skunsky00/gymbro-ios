//
//  EntitlementService.swift
//  Gym Bro
//
//  Created by Jacob Johnson on 10/30/26.
//

import Foundation
import FirebaseFunctions

enum EntitlementError: Error { case badResponse }

final class EntitlementService {
    static let shared = EntitlementService()
    private let functions = Functions.functions(region: "us-central1")
    private init() {}

    func fetchLikeStatus() async throws -> LikeStatus {
        let result = try await functions.httpsCallable("getLikeStatus").call()
        guard let data = result.data as? [String: Any] else { throw EntitlementError.badResponse }
        return LikeStatus(
            isPremium: (data["premium"] as? Bool) ?? false,
            limit: data["limit"] as? Int,
            remaining: data["remaining"] as? Int
        )
    }

    func fetchReceivedLikes() async throws -> ReceivedLikesResponse {
        let result = try await functions.httpsCallable("getReceivedLikes").call(["mode": "all"])
        guard let data = result.data as? [String: Any] else { throw EntitlementError.badResponse }

        let rows = data["likes"] as? [[String: Any]] ?? []
        let likes: [ReceivedLike] = rows.compactMap { row in
            guard let from = row["fromID"] as? String else { return nil }
            let millis = (row["createdAt"] as? Double) ?? 0
            return ReceivedLike(fromID: from,
                                mode: MatchMode(rawValue: row["mode"] as? String ?? "") ?? .train,
                                photoURL: row["photoURL"] as? String,
                                comment: row["comment"] as? String,
                                createdAt: Date(timeIntervalSince1970: millis / 1000))
        }
        let counts = data["counts"] as? [String: Any] ?? [:]
        return ReceivedLikesResponse(isPremium: (data["premium"] as? Bool) ?? false,
                                     trainCount: counts["train"] as? Int ?? 0,
                                     dateCount: counts["date"] as? Int ?? 0,
                                     likes: likes)
    }
}
