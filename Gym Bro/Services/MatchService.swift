//
//  MatchService.swift
//  Gym Bro
//
//  Created by Jacob Johnson on 10/23/26.
//

import Foundation
import FirebaseFirestore

final class MatchService {
    static let shared = MatchService()
    private let db = Firestore.firestore()
    private init() {}

    func listenToMatches(for uid: String,
                         onChange: @escaping ([Match]) -> Void) -> ListenerRegistration {
        db.collection("matches")
            .whereField("userIds", arrayContains: uid)
            .addSnapshotListener { snapshot, error in
                guard let snapshot else {
                    print("matches listener error:", error?.localizedDescription ?? "unknown")
                    return
                }
                onChange(snapshot.documents.compactMap { Match($0) })
            }
    }

    func listenToMessages(matchID: String,
                          onChange: @escaping ([ChatMessage]) -> Void) -> ListenerRegistration {
        db.collection("matches").document(matchID).collection("messages")
            .order(by: "createdAt")
            .addSnapshotListener { snapshot, error in
                guard let snapshot else {
                    print("messages listener error:", error?.localizedDescription ?? "unknown")
                    return
                }
                onChange(snapshot.documents.compactMap { ChatMessage($0) })
            }
    }

    func sendText(_ text: String, matchID: String, senderID: String) async throws {
        try await write(
            ["senderID": senderID, "kind": "text", "text": text],
            preview: text,
            matchID: matchID
        )
    }

    func sendSession(startTime: Date, focus: String, gymName: String?, preview: String,
                     matchID: String, senderID: String) async throws {
        var fields: [String: Any] = [
            "senderID": senderID, "kind": "session", "focus": focus,
            "startTime": Timestamp(date: startTime), "status": "pending"
        ]
        if let gymName { fields["gymName"] = gymName }
        try await write(fields, preview: preview, matchID: matchID)
    }

    func respond(toMessage messageID: String, matchID: String, accept: Bool) async throws {
        try await db.collection("matches").document(matchID)
            .collection("messages").document(messageID)
            .updateData(["status": accept ? "accepted" : "declined"])
    }

    /// Writes the message and updates the match's preview in one atomic batch.
    private func write(_ fields: [String: Any], preview: String, matchID: String) async throws {
        let matchRef = db.collection("matches").document(matchID)
        let messageRef = matchRef.collection("messages").document()
        let now = Timestamp(date: Date())

        var data = fields
        data["createdAt"] = now

        var matchUpdate: [String: Any] = ["lastMessage": preview, "lastMessageAt": now]
        if let sender = fields["senderID"] as? String {
            matchUpdate["lastSenderID"] = sender
        }

        let batch = db.batch()
        batch.setData(data, forDocument: messageRef)
        batch.updateData(matchUpdate, forDocument: matchRef)
        try await batch.commit()
    }

    /// Marks everything in this match as seen by `userID`.
    func markRead(matchID: String, userID: String) async {
        let ref = db.collection("matches").document(matchID)
        do {
            let snap = try await ref.getDocument()
            guard snap.exists else { return }
            // Use the match's own last-message time (or a tiny sentinel if there are no
            // messages yet) so phone clocks never matter.
            let seenUpTo = (snap.data()?["lastMessageAt"] as? Timestamp)
                ?? Timestamp(seconds: 1, nanoseconds: 0)
            let current = (snap.data()?["readAt"] as? [String: Timestamp])?[userID]
            if current == seenUpTo { return }
            try await ref.updateData(["readAt.\(userID)": seenUpTo])
        } catch {
            print("markRead error:", error)
        }
    }
}
