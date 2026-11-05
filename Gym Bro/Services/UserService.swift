//
//  UserService.swift
//  Gym Bro
//
//  Created by Jacob Johnson on 10/23/26.
//

import Foundation
import FirebaseFirestore
import FirebaseFunctions

final class UserService {
    static let shared = UserService()
    private let users = Firestore.firestore().collection("users")
    private init() {}

    func fetchUser(id: String) async throws -> AppUser? {
        let snapshot = try await users.document(id).getDocument()
        guard snapshot.exists else { return nil }
        return try snapshot.data(as: AppUser.self)
    }
    
    func fetchUsers(ids: [String]) async throws -> [AppUser] {
        var result: [AppUser] = []
        var index = 0
        while index < ids.count {
            let chunk = Array(ids[index..<min(index + 10, ids.count)])
            let snapshot = try await users
                .whereField(FieldPath.documentID(), in: chunk)
                .getDocuments()
            result.append(contentsOf: snapshot.documents.compactMap { try? $0.data(as: AppUser.self) })
            index += 10
        }
        return result
    }

    func save(_ user: AppUser) throws {
        try users.document(user.id).setData(from: user, merge: true)
    }
    
    func updateCaption(uid: String, caption: String) async throws {
        let trimmed = caption.trimmingCharacters(in: .whitespacesAndNewlines)
        _ = try await Functions.functions(region: "us-central1")
            .httpsCallable("setCaption")
            .call(["caption": trimmed])
    }
    
    func saveAdvancedFilters(uid: String, styles: [TrainingStyle], goals: [FitnessGoal],
                             minBench: Int, minSquat: Int, minDeadlift: Int) async throws {
        func list(_ values: [Any]) -> Any { values.isEmpty ? FieldValue.delete() : values }
        func number(_ value: Int) -> Any { value > 0 ? value : FieldValue.delete() }
        try await users.document(uid).updateData([
            "prefs.styles": list(styles.map { $0.rawValue as Any }),
            "prefs.goals": list(goals.map { $0.rawValue as Any }),
            "prefs.minBenchLb": number(minBench),
            "prefs.minSquatLb": number(minSquat),
            "prefs.minDeadliftLb": number(minDeadlift)
        ])
    }
}

