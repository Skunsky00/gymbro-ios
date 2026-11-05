//
//  ChatViewModel.swift
//  Gym Bro
//
//  Created by Jacob Johnson on 10/23/26.
//

import SwiftUI
import Combine
import FirebaseFirestore

@MainActor
final class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var draft = ""
    @Published var errorMessage: String?
    @Published var isEnded = false

    let match: Match
    let other: AppUser
    let myID: String
    let myGym: Gym?

    private var listener: ListenerRegistration?
    private let service = MatchService.shared
    private let safety = SafetyService.shared

    init(match: Match, other: AppUser, myID: String, myGym: Gym?) {
        self.match = match
        self.other = other
        self.myID = myID
        self.myGym = myGym
    }

    var canSend: Bool {
        !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func start() {
        guard listener == nil else { return }
        listener = service.listenToMessages(matchID: match.id) { [weak self] messages in
            Task { @MainActor in self?.messages = messages }
        }
    }

    func stop() {
        listener?.remove()
        listener = nil
    }

    func send() async {
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        draft = ""
        errorMessage = nil
        do {
            try await service.sendText(text, matchID: match.id, senderID: myID)
        } catch {
            draft = text
            errorMessage = "Couldn't send. Try again."
            print("send error:", error)
        }
    }

    func propose(startTime: Date, focus: String, gymName: String?) async {
        errorMessage = nil
        let when = startTime.formatted(.dateTime.weekday(.abbreviated).month().day().hour().minute())
        do {
            try await service.sendSession(startTime: startTime,
                                          focus: focus,
                                          gymName: gymName,
                                          preview: "Proposed a session: \(focus), \(when)",
                                          matchID: match.id,
                                          senderID: myID)
        } catch {
            errorMessage = "Couldn't send the proposal. Try again."
            print("propose error:", error)
        }
    }

    func respond(to message: ChatMessage, accept: Bool) async {
        errorMessage = nil
        do {
            try await service.respond(toMessage: message.id, matchID: match.id, accept: accept)
        } catch {
            errorMessage = "Couldn't update the session. Try again."
            print("respond error:", error)
        }
    }
    func unmatch() async {
        do {
            try await safety.endMatch(matchID: match.id, by: myID)
            isEnded = true
        } catch {
            errorMessage = "Couldn't unmatch. Try again."
            print("unmatch error:", error)
        }
    }

    func block() async {
        do {
            try await safety.block(other.id, by: myID, matchID: match.id)
            isEnded = true
        } catch {
            errorMessage = "Couldn't block. Try again."
            print("block error:", error)
        }
    }

    func report(reason: ReportReason, details: String, alsoBlock: Bool) async {
        do {
            try await safety.report(reportedID: other.id, reporterID: myID,
                                    reason: reason, details: details, matchID: match.id)
            if alsoBlock {
                try await safety.block(other.id, by: myID, matchID: match.id)
                isEnded = true
            }
        } catch {
            errorMessage = "Couldn't send the report. Try again."
            print("report error:", error)
        }
    }
}
