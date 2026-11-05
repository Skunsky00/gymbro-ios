//
//  AccountService.swift
//  Gym Bro
//
//  Created by Jacob Johnson on 10/24/26.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

enum AccountError: LocalizedError {
    case needsRecentLogin

    var errorDescription: String? {
        "For security, sign out, sign back in, then delete your account again."
    }
}

final class AccountService {
    static let shared = AccountService()
    private let db = Firestore.firestore()
    private init() {}

    func deleteAccount() async throws {
        guard let user = Auth.auth().currentUser else { return }
        let uid = user.uid

        // Firebase only lets you delete an account soon after signing in.
        // Check up front so we don't delete data and then fail.
        let token = try await user.getIDTokenResult()
        guard Date().timeIntervalSince(token.authDate) < 4 * 60 else {
            throw AccountError.needsRecentLogin
        }
        
        let tokens = try await db.collection("users").document(uid)
            .collection("fcmTokens").getDocuments()


        // 1. Photos
        let photos = try await Storage.storage().reference()
            .child("users/\(uid)/photos").listAll()
        for item in photos.items {
            try await item.delete()
        }

        // 2. Firestore data
        let likes = try await db.collection("likes")
            .whereField("from", isEqualTo: uid).getDocuments()
        let blocks = try await db.collection("blocks")
            .whereField("from", isEqualTo: uid).getDocuments()
        let passes = try await db.collection("users").document(uid)
            .collection("passes").getDocuments()
        let matches = try await db.collection("matches")
            .whereField("userIds", arrayContains: uid).getDocuments()

        let now = Timestamp(date: Date())
        let batch = db.batch()
        likes.documents.forEach { batch.deleteDocument($0.reference) }
        blocks.documents.forEach { batch.deleteDocument($0.reference) }
        passes.documents.forEach { batch.deleteDocument($0.reference) }
        tokens.documents.forEach { batch.deleteDocument($0.reference) }
        for doc in matches.documents where doc.data()["endedBy"] == nil {
            batch.updateData(["endedBy": uid, "endedAt": now], forDocument: doc.reference)
        }
        batch.deleteDocument(db.collection("users").document(uid))
        try await batch.commit()

        // 3. The login itself
        try await user.delete()
    }
}
