//
//  ProfileView.swift
//  Gym Bro
//
//  Created by Jacob Johnson on 10/24/26.
//

import SwiftUI
import FirebaseAuth
import UserNotifications

struct ProfileView: View {
    @EnvironmentObject var auth: AuthViewModel
    @StateObject private var vm = ProfileViewModel()
    @State private var showEdit = false
    @State private var showDeleteConfirm = false
    @State private var isDeleting = false
    @State private var errorMessage: String?
    @State private var notifStatus: UNAuthorizationStatus = .notDetermined

    var body: some View {
        NavigationStack {
            List {
                if let user = vm.user {
                    Section {
                        Button { showEdit = true } label: { header(user) }
                            .buttonStyle(.plain)
                    }
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)

                    Section { PremiumStatusRow() }

                    Section("Preferences") {
                        NavigationLink("Discovery preferences") {
                            DiscoveryPreferencesView()
                        }
                        if FeatureFlags.dating {
                            NavigationLink("Dating preferences") {
                                DatingPreferencesView()
                            }
                        }
                    }
                } else if vm.isLoading {
                    ProgressView().frame(maxWidth: .infinity)
                }

                Section("Notifications") {
                    switch notifStatus {
                    case .authorized, .provisional, .ephemeral:
                        Label("Notifications are on", systemImage: "bell.fill")
                            .foregroundStyle(.secondary)
                    case .denied:
                        Button("Turn on in Settings") {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        }
                        .foregroundStyle(Color.primary)
                    default:
                        Button("Turn on notifications") {
                            Task {
                                await NotificationService.shared.requestPermission()
                                notifStatus = await NotificationService.shared.authorizationStatus()
                            }
                        }
                        .foregroundStyle(Color.primary)
                    }
                }

                Section {
                    Button("Sign out") {
                        Task {
                            await NotificationService.shared.removeToken()
                            await PurchaseService.shared.reset()
                            auth.signOut()
                        }
                    }
                    .foregroundStyle(Color.primary)
                }

                Section {
                    Button("Delete account", role: .destructive) {
                        showDeleteConfirm = true
                    }
                } footer: {
                    Text("Permanently deletes your profile, photos and likes. This can't be undone. Deleting your account doesn't cancel a subscription. Manage it in your App Store account settings.")
                }

                if let errorMessage {
                    Text(errorMessage).foregroundStyle(.red).font(.footnote)
                }
            }
            .navigationTitle("Profile")
            .overlay { if isDeleting { ProgressView().controlSize(.large) } }
            .task { await reload() }
            .task { notifStatus = await NotificationService.shared.authorizationStatus() }
            .task { await PurchaseService.shared.refreshFromServer() }
            .navigationDestination(isPresented: $showEdit) {
                EditProfileView { Task { await reload() } }
            }
            .confirmationDialog("Delete your account?",
                                isPresented: $showDeleteConfirm,
                                titleVisibility: .visible) {
                Button("Delete account", role: .destructive) {
                    Task { await deleteAccount() }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This permanently deletes your profile and photos.")
            }
        }
    }

    private func header(_ user: AppUser) -> some View {
        VStack(spacing: 10) {
            Avatar(urlString: user.photoURLs?.first, size: 120)
                .overlay(Circle().stroke(Color.primary.opacity(0.1), lineWidth: 1))
            Text("\(user.firstName)\(user.age.map { ", \($0)" } ?? "")")
                .font(.title2.bold())
            if let gym = user.homeGym {
                Text(gym.name).font(.subheadline).foregroundStyle(.secondary)
            }
            Text("Edit profile")
                .font(.subheadline.bold())
                .foregroundStyle(Color(.systemBackground))
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background(Color.primary, in: Capsule())
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    private func reload() async {
        if let uid = auth.userSession?.uid {
            await vm.load(userID: uid)
        }
    }

    private func deleteAccount() async {
        isDeleting = true
        errorMessage = nil
        defer { isDeleting = false }
        do {
            try await AccountService.shared.deleteAccount()
            await PurchaseService.shared.reset()
            auth.signOut()
        } catch let error as AccountError {
            errorMessage = error.localizedDescription
        } catch {
            if (error as NSError).code == 17014 { // requires recent login
                errorMessage = AccountError.needsRecentLogin.localizedDescription
            } else {
                errorMessage = "Couldn't delete your account. Try again."
            }
            print("delete account error:", error)
        }
    }
}
