//
//  Gym_BroApp.swift
//  Gym Bro
//
//  Created by Jacob Johnson on 10/23/26.
//

import SwiftUI
import UIKit
import UserNotifications
import FirebaseCore
import FirebaseAuth
import FirebaseMessaging

class AppDelegate: NSObject, UIApplicationDelegate,
                   UNUserNotificationCenterDelegate, MessagingDelegate {

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        FirebaseApp.configure()
        PurchaseService.configure()
        UNUserNotificationCenter.current().delegate = self
        Messaging.messaging().delegate = self
        application.registerForRemoteNotifications()
        return true
    }

    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Auth.auth().setAPNSToken(deviceToken, type: .unknown)
        Messaging.messaging().apnsToken = deviceToken
    }

    func application(_ application: UIApplication,
                     didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        if Auth.auth().canHandleNotification(userInfo) {
            completionHandler(.noData)
            return
        }
        completionHandler(.noData)
    }

    // Firebase gave us a notification token for this phone.
    nonisolated func messaging(_ messaging: Messaging,
                               didReceiveRegistrationToken fcmToken: String?) {
        guard let fcmToken else { return }
        Task { @MainActor in
            await NotificationService.shared.save(token: fcmToken)
        }
    }

    // Show a banner while the app is open, except for the chat you're looking at.
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler:
            @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let matchID = notification.request.content.userInfo["matchID"] as? String
        DispatchQueue.main.async {
            MainActor.assumeIsolated {
                if let matchID, AppRouter.shared.activeChatMatchID == matchID {
                    completionHandler([])
                } else {
                    completionHandler([.banner, .sound])
                }
            }
        }
    }

    // The user tapped a notification: open that chat.
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let matchID = response.notification.request.content.userInfo["matchID"] as? String
        DispatchQueue.main.async {
            MainActor.assumeIsolated {
                AppRouter.shared.openMatches(matchID: matchID)
            }
        }
        completionHandler()
    }
}

@main
struct GymBroApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var authViewModel = AuthViewModel()

    var body: some Scene {
        WindowGroup {
            Group {
                if authViewModel.userSession != nil {
                    OnboardingFlowView()
                } else {
                    PhoneEntryView()
                }
            }
            .environmentObject(authViewModel)
        }
    }
}
