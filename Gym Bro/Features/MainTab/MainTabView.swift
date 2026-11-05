//
//  MainTabView.swift
//  Gym Bro
//
//  Created by Jacob Johnson on 10/23/26.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import Combine

@MainActor
final class UnreadViewModel: ObservableObject {
    @Published var count = 0
    private var listener: ListenerRegistration?
    private var myID: String?

    func start(userID: String) {
        if myID == userID, listener != nil { return }
        stop()
        myID = userID
        listener = MatchService.shared.listenToMatches(for: userID) { [weak self] matches in
            let unread = matches.filter { $0.isUnread(for: userID) }.count
            Task { @MainActor in self?.count = unread }
        }
    }

    func stop() {
        listener?.remove()
        listener = nil
        myID = nil
        count = 0
    }
}

struct MainTabView: View {
    @EnvironmentObject var auth: AuthViewModel
    @ObservedObject private var router = AppRouter.shared
    @StateObject private var unread = UnreadViewModel()

    var body: some View {
        TabView(selection: $router.selectedTab) {
            DiscoverContainerView()
                .tabItem { Label("Discover", systemImage: "figure.strengthtraining.traditional") }
                .tag(AppRouter.Tab.discover)
            
            LikesView()
                .tabItem { Label("Likes", systemImage: "heart") }
                .tag(AppRouter.Tab.likes)

            MatchesView()
                .tabItem { Label("Matches", systemImage: "bubble.left.and.bubble.right") }
                .badge(unread.count)
                .tag(AppRouter.Tab.matches)

            ProfileView()
                .tabItem { Label("Profile", systemImage: "person.crop.circle") }
                .tag(AppRouter.Tab.profile)
        }
        .tint(.primary)
        .task { await NotificationService.shared.syncToken() }
        .task(id: auth.userSession?.uid) {
            if let uid = auth.userSession?.uid { unread.start(userID: uid) }
            if let uid = auth.userSession?.uid { await PurchaseService.shared.identify(uid: uid) }
        }
        .onDisappear { unread.stop() }
    }
}
