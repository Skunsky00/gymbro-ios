//
//  DatingService.swift
//  Gym Bro
//
//  Created by Jacob Johnson on 11/2/26.
//

import Foundation
import FirebaseFunctions

final class DatingService {
    static let shared = DatingService()
    private let functions = Functions.functions(region: "us-central1")
    private init() {}

    private static let badResponse = NSError(
        domain: "DatingService", code: -1,
        userInfo: [NSLocalizedDescriptionKey: "Unexpected response."])

    /// Your own preferences. They come from the server, because nobody else may read them.
    func fetchMyPrefs() async throws -> DatingPrefs {
        let result = try await functions.httpsCallable("getDatingPrefs").call()
        guard let data = result.data as? [String: Any] else { throw Self.badResponse }
        var prefs = DatingPrefs()
        prefs.enabled = data["enabled"] as? Bool ?? false
        let raw = data["interestedIn"] as? [String] ?? []
        prefs.interestedIn = Set(raw.compactMap { Gender(rawValue: $0) })
        prefs.minAge = data["minAge"] as? Int ?? 18
        prefs.maxAge = data["maxAge"] as? Int ?? 45
        return prefs
    }

    func save(_ prefs: DatingPrefs) async throws {
        var payload: [String: Any] = ["enabled": prefs.enabled]
        if prefs.enabled {
            payload["interestedIn"] = prefs.interestedIn.map(\.rawValue).sorted()
            payload["minAge"] = prefs.minAge
            payload["maxAge"] = prefs.maxAge
        }
        _ = try await functions.httpsCallable("saveDatingPrefs").call(payload)
    }

    /// IDs of people you could date, already filtered both ways by the server.
    func fetchCandidateIDs(gym: Gym, radiusMiles: Int) async throws -> [String] {
        var prefixes: [String] = []
        if radiusMiles > 0 && gym.geohash != nil {
            prefixes = Geohash.coveringPrefixes(latitude: gym.latitude,
                                                longitude: gym.longitude,
                                                radiusMeters: Double(radiusMiles) * 1609.34)
        }
        let result = try await functions.httpsCallable("getDateCandidates")
            .call(["gymID": gym.id, "prefixes": prefixes])
        guard let data = result.data as? [String: Any],
              let ids = data["ids"] as? [String] else { throw Self.badResponse }
        return ids
    }

    /// True when the server says Dating isn't turned on yet.
    static func isNotSetUp(_ error: Error) -> Bool {
        let ns = error as NSError
        return ns.domain.lowercased().contains("functions")
            && ns.code == FunctionsErrorCode.failedPrecondition.rawValue
    }

    /// Plain-language text for an error. The raw error is printed for debugging.
    static func message(for error: Error) -> String {
        let ns = error as NSError
        print("dating error:", ns.domain, ns.code, ns.localizedDescription)
        if ns.domain.lowercased().contains("functions"),
           let code = FunctionsErrorCode(rawValue: ns.code) {
            switch code {
            case .failedPrecondition, .invalidArgument:
                return ns.localizedDescription
            case .unauthenticated:
                return ns.localizedDescription == "UNAUTHENTICATED"
                    ? "The server rejected the request. Its permissions may need fixing."
                    : "Your session expired. Sign out and back in."
            case .notFound:
                return ns.localizedDescription == "NOT_FOUND"
                    ? "This feature isn't on the server yet. Deploy the latest functions."
                    : ns.localizedDescription
            case .unavailable, .deadlineExceeded:
                return "Can't reach the server. Check your connection and try again."
            default:
                break
            }
        }
        return "Something went wrong (code \(ns.code)). Try again."
    }
}
