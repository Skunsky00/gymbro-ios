//
//  DiscoverService.swift
//  Gym Bro
//
//  Created by Jacob Johnson on 10/23/26.
//

import Foundation
import FirebaseFirestore
import FirebaseFunctions

final class DiscoverService {
    static let shared = DiscoverService()
    private let db = Firestore.firestore()
    private init() {}

    func fetchCandidates(gymID: String, limit: Int = 50) async throws -> [AppUser] {
        let snapshot = try await db.collection("users")
            .whereField("onboardingComplete", isEqualTo: true)
            .whereField("homeGym.id", isEqualTo: gymID)
            .limit(to: limit)
            .getDocuments()
        return snapshot.documents.compactMap { doc in
            guard (doc.data()["hidden"] as? Bool) != true else { return nil }
            return try? doc.data(as: AppUser.self)
        }
    }

    func fetchLikedIDs(by uid: String) async throws -> Set<String> {
        let snapshot = try await db.collection("likes")
            .whereField("from", isEqualTo: uid)
            .getDocuments()
        return Set(snapshot.documents.compactMap { doc in
            guard (doc["mode"] as? String ?? "train") == "train" else { return nil }
            return doc["to"] as? String
        })
    }

    func fetchPassedIDs(by uid: String) async throws -> Set<String> {
        let snapshot = try await db.collection("users").document(uid)
            .collection("passes").getDocuments()
        return Set(snapshot.documents.map(\.documentID))
    }

    func pass(from uid: String, to targetID: String, mode: MatchMode = .train) async throws {
        let docID = mode == .date ? "\(targetID)_date" : targetID
        try await db.collection("users").document(uid)
            .collection("passes").document(docID)
            .setData(["createdAt": Timestamp(date: Date())])
    }

    
    
    func fetchNearby(gym: Gym, radiusMiles: Int, perCellLimit: Int = 50) async throws -> [AppUser] {
        let prefixes = Geohash.coveringPrefixes(latitude: gym.latitude,
                                                longitude: gym.longitude,
                                                radiusMeters: Double(radiusMiles) * 1609.34)
        var found: [String: AppUser] = [:]
        for prefix in prefixes {
            let snapshot = try await db.collection("users")
                .whereField("onboardingComplete", isEqualTo: true)
                .whereField("homeGym.geohash", isGreaterThanOrEqualTo: prefix)
                .whereField("homeGym.geohash", isLessThanOrEqualTo: prefix + "~")
                .limit(to: perCellLimit)
                .getDocuments()
            for doc in snapshot.documents {
                guard (doc.data()["hidden"] as? Bool) != true else { continue }
                if let user = try? doc.data(as: AppUser.self) { found[user.id] = user }
            }
        }
        // The cells are square, the radius is a circle, so trim to the exact distance.
        return found.values.filter { user in
            guard let theirGym = user.homeGym else { return false }
            return gym.distanceMiles(to: theirGym) <= Double(radiusMiles)
        }
    }
    /// Sends a like through the server. `matched` is true on a mutual like.
    func sendLike(to targetID: String, mode: MatchMode = .train,photoURL: String? = nil, comment: String? = nil) async throws -> LikeResult {
        var payload: [String: Any] = ["targetID": targetID, "mode": mode.rawValue]
        if let photoURL { payload["photoURL"] = photoURL }
        if let trimmed = comment?.trimmingCharacters(in: .whitespacesAndNewlines), !trimmed.isEmpty {
            payload["comment"] = trimmed
        }
        let result = try await Functions.functions(region: "us-central1")
            .httpsCallable("sendLike")
            .call(payload)

        guard let data = result.data as? [String: Any],
              let matched = data["matched"] as? Bool else {
            throw NSError(domain: "DiscoverService", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "Unexpected response from sendLike."])
        }
        return LikeResult(matched: matched, remaining: data["remaining"] as? Int)
    }

    /// True when the server refused a like because the free daily limit is used up.
    static func isOutOfLikes(_ error: Error) -> Bool {
        let ns = error as NSError
        if ns.code == FunctionsErrorCode.resourceExhausted.rawValue { return true }
        return ns.localizedDescription.localizedCaseInsensitiveContains("out of likes")
    }

}
