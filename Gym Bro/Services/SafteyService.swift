//
//  SafteyService.swift
//  Gym Bro
//
//  Created by Jacob Johnson on 10/24/26.
//

import Foundation
import FirebaseFirestore

enum ReportReason: String, CaseIterable, Identifiable {
    case inappropriatePhotos, harassment, fakeOrSpam, underage, unsafe, other

    var id: String { rawValue }

    var title: String {
        switch self {
        case .inappropriatePhotos: return "Inappropriate photos"
        case .harassment: return "Harassment or hate"
        case .fakeOrSpam: return "Fake profile or spam"
        case .underage: return "Seems under 18"
        case .unsafe: return "Made me feel unsafe"
        case .other: return "Something else"
        }
    }
}

final class SafetyService {
    static let shared = SafetyService()
    private let db = Firestore.firestore()
    private init() {}

    /// Everyone I blocked plus everyone who blocked me.
    func fetchBlockedIDs(for uid: String) async throws -> Set<String> {
        async let byMe = db.collection("blocks").whereField("from", isEqualTo: uid).getDocuments()
        async let ofMe = db.collection("blocks").whereField("to", isEqualTo: uid).getDocuments()
        let mine = try await byMe
        let theirs = try await ofMe
        let blockedByMe = mine.documents.compactMap { $0["to"] as? String }
        let blockedMe = theirs.documents.compactMap { $0["from"] as? String }
        return Set(blockedByMe + blockedMe)
    }

    /// Blocks someone and ends every active match with them, train or date.
    func block(_ targetID: String, by uid: String, matchID: String?) async throws {
        let now = Timestamp(date: Date())

        let mine = try await db.collection("matches")
            .whereField("userIds", arrayContains: uid).getDocuments()
        let active = mine.documents.filter { doc in
            let data = doc.data()
            let ids = data["userIds"] as? [String] ?? []
            return ids.contains(targetID) && data["endedBy"] == nil
        }

        let batch = db.batch()
        batch.setData(["from": uid, "to": targetID, "createdAt": now],
                      forDocument: db.collection("blocks").document("\(uid)_\(targetID)"))
        for doc in active {
            batch.updateData(["endedBy": uid, "endedAt": now], forDocument: doc.reference)
        }
        try await batch.commit()
    }

    func endMatch(matchID: String, by uid: String) async throws {
        try await db.collection("matches").document(matchID)
            .updateData(["endedBy": uid, "endedAt": Timestamp(date: Date())])
    }

    func report(reportedID: String, reporterID: String, reason: ReportReason,
                details: String, matchID: String?) async throws {
        var data: [String: Any] = [
            "reporterID": reporterID,
            "reportedID": reportedID,
            "reason": reason.rawValue,
            "createdAt": Timestamp(date: Date())
        ]
        let trimmed = details.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty { data["details"] = String(trimmed.prefix(500)) }
        if let matchID { data["matchID"] = matchID }
        _ = try await db.collection("reports").addDocument(data: data)
    }
}
