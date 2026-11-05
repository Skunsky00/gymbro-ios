//
//  NotificationService.swift
//  Gym Bro
//
//  Created by Jacob Johnson on 10/24/26.
//

import UIKit
import UserNotifications
import FirebaseAuth
import FirebaseFirestore
import FirebaseMessaging

@MainActor
final class NotificationService {
    static let shared = NotificationService()
    private let db = Firestore.firestore()
    private var currentToken: String?
    private init() {}

    func authorizationStatus() async -> UNAuthorizationStatus {
        await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
    }

    @discardableResult
    func requestPermission() async -> Bool {
        let granted = (try? await UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .badge, .sound])) ?? false
        if granted { UIApplication.shared.registerForRemoteNotifications() }
        return granted
    }

    /// Called when Firebase hands us a new or refreshed token.
    func save(token: String) async {
        currentToken = token
        await syncToken()
    }

    /// Stores this phone's token under whoever is signed in.
    func syncToken() async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        if currentToken == nil {
            currentToken = try? await Messaging.messaging().token()
        }
        guard let token = currentToken else { return }
        do {
            try await db.collection("users").document(uid)
                .collection("fcmTokens").document(token)
                .setData(["token": token,
                          "platform": "ios",
                          "updatedAt": Timestamp(date: Date())])
        } catch {
            print("save token error:", error)
        }
    }

    /// Call before signing out, so this phone stops getting that person's notifications.
    func removeToken() async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        if currentToken == nil {
            currentToken = try? await Messaging.messaging().token()
        }
        guard let token = currentToken else { return }
        try? await db.collection("users").document(uid)
            .collection("fcmTokens").document(token).delete()
    }
}
