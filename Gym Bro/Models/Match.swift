//
//  Match.swift
//  Gym Bro
//
//  Created by Jacob Johnson on 10/23/26.
//

import Foundation
import FirebaseFirestore

struct Match: Identifiable, Hashable {
    let id: String
    let userIDs: [String]
    let createdAt: Date
    let createdBy: String?
    var lastMessage: String?
    var lastMessageAt: Date?
    var lastSenderID: String?
    var readAt: [String: Date]
    let endedBy: String?
    let mode: MatchMode

    init?(_ doc: DocumentSnapshot) {
        guard let data = doc.data(),
              let ids = data["userIds"] as? [String] else { return nil }
        id = doc.documentID
        userIDs = ids
        createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
        createdBy = data["createdBy"] as? String
        lastMessage = data["lastMessage"] as? String
        lastMessageAt = (data["lastMessageAt"] as? Timestamp)?.dateValue()
        lastSenderID = data["lastSenderID"] as? String
        let rawRead = data["readAt"] as? [String: Timestamp] ?? [:]
        readAt = rawRead.mapValues { $0.dateValue() }
        endedBy = data["endedBy"] as? String
        mode = MatchMode(rawValue: data["mode"] as? String ?? "") ?? .train
    }

    func otherUserID(me: String) -> String? {
        userIDs.first { $0 != me }
    }

    /// True if there is something here the given user hasn't seen.
    func isUnread(for me: String) -> Bool {
        guard endedBy == nil else { return false }

        // New match nobody has messaged: unread until you open it
        // (the person who completed the match already saw the match screen).
        guard let lastAt = lastMessageAt else {
            return createdBy != me && readAt[me] == nil
        }

        // Matches from before this feature have no lastSenderID, so they stay "read".
        guard let sender = lastSenderID, sender != me else { return false }
        guard let seen = readAt[me] else { return true }
        return seen < lastAt
    }
}
