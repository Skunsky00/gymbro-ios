//
//  ChatMessage.swift
//  Gym Bro
//
//  Created by Jacob Johnson on 10/23/26.
//

import Foundation
import FirebaseFirestore

enum SessionStatus: String {
    case pending, accepted, declined
}

struct SessionProposal {
    var startTime: Date
    var focus: String
    var status: SessionStatus
    var gymName: String?
}

struct ChatMessage: Identifiable {
    enum Content {
        case text(String)
        case session(SessionProposal)
    }

    let id: String
    let senderID: String
    let createdAt: Date
    let content: Content

    init?(_ doc: QueryDocumentSnapshot) {
        let data = doc.data()
        guard let sender = data["senderID"] as? String else { return nil }
        id = doc.documentID
        senderID = sender
        createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()

        if data["kind"] as? String == "session" {
            guard let start = data["startTime"] as? Timestamp,
                  let focus = data["focus"] as? String else { return nil }
            let status = SessionStatus(rawValue: data["status"] as? String ?? "") ?? .pending
            content = .session(SessionProposal(startTime: start.dateValue(),
                                               focus: focus,
                                               status: status,
                                               gymName: data["gymName"] as? String))
        } else {
            content = .text(data["text"] as? String ?? "")
        }
    }
}
