//
//  DiscoverView.swift
//  Gym Bro
//
//  Created by Jacob Johnson on 10/23/26.
//

import SwiftUI
import FirebaseAuth

struct DiscoverView: View {
    let mode: MatchMode
    let isActive: Bool

    @EnvironmentObject var auth: AuthViewModel
    @StateObject private var vm: DiscoverViewModel
    @State private var likingPhoto: PhotoLikeTarget?
    @State private var showDatingSetup = false
    @ObservedObject private var purchases = PurchaseService.shared

    init(mode: MatchMode = .train, isActive: Bool = true) {
        self.mode = mode
        self.isActive = isActive
        _vm = StateObject(wrappedValue: DiscoverViewModel(mode: mode))
    }

    var body: some View {
        Group {
            if vm.isLoading && vm.queue.isEmpty {
                ProgressView()
            } else if vm.needsDatingSetup {
                datingPrompt
            } else if let current = vm.current {
                ScrollView {
                    ProfileCardView(user: current,
                                    overlap: vm.overlap(with: current),
                                    gymNote: vm.gymNote(for: current),
                                    onLikePhoto: { url in
                                        if vm.likesRemaining == 0 {
                                            vm.paywallReason = .unlimitedLikes
                                        } else {
                                            likingPhoto = PhotoLikeTarget(url: url)
                                        }
                                    })
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        .padding(.bottom, 24)
                }
                .id(current.id)
                .overlay(alignment: .bottomLeading) { skipButton }
            } else {
                emptyState
            }
        }
        .task(id: isActive) {
            if isActive { await reload() }
        }
        .overlay(alignment: .topTrailing) {
            if let current = vm.current {
                SafetyMenu(
                    name: current.firstName,
                    onPhoto: true,
                    onBlock: { await vm.block(current) },
                    onReport: { reason, details, alsoBlock in
                        await vm.report(current, reason: reason, details: details, alsoBlock: alsoBlock)
                    }
                )
                .padding(.trailing, 28)
                .padding(.top, 16)
            }
        }
        .onChange(of: purchases.isPremium) { _, _ in Task { await reload() } }
        .overlay(alignment: .topLeading) {
            if vm.current != nil, let left = vm.likesRemaining {
                Button { vm.paywallReason = .unlimitedLikes } label: {
                    Text(left == 1 ? "1 like left" : "\(left) likes left")
                        .font(.footnote.bold())
                        .foregroundStyle(Color.primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(.regularMaterial, in: Capsule())
                }
                .padding(.leading, 20)
                .padding(.top, 16)
            }
        }
        .sheet(item: $vm.paywallReason) { reason in
            PaywallView(reason: reason)
                .presentationDetents([.medium, .large])
        }
        .sheet(item: $vm.newMatch) { MatchView(user: $0, mode: mode) }
        .sheet(item: $likingPhoto) { target in
            PhotoLikeSheet(name: vm.current?.firstName ?? "them", photoURL: target.url) { comment in
                Task { await vm.likePhoto(url: target.url, comment: comment) }
            }
            .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showDatingSetup) {
            DatingSetupView { Task { await reload() } }
        }
        .alert("Couldn't send like",
               isPresented: Binding(get: { vm.likeError != nil },
                                    set: { if !$0 { vm.likeError = nil } })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(vm.likeError ?? "")
        }
    }
    


    private var skipButton: some View {
        Button { Task { await vm.pass() } } label: {
            Image(systemName: "xmark")
                .font(.title2.bold())
                .foregroundStyle(Color.primary)
                .frame(width: 60, height: 60)
                .background(.regularMaterial, in: Circle())
                .overlay(Circle().stroke(Color.primary.opacity(0.1), lineWidth: 1))
                .shadow(color: .black.opacity(0.18), radius: 8, y: 3)
        }
        .accessibilityLabel("Skip")
        .padding(.leading, 20)
        .padding(.bottom, 16)
    }

    private var datingPrompt: some View {
        VStack(spacing: 14) {
            Image(systemName: "heart.fill")
                .font(.system(size: 52))
                .foregroundStyle(Color.dateAccent)
            Text("Meet people at your gym").font(.title3.bold())
            Text("Turn on Dating to see people who want to go out. Date matches stay separate from your gym partners.")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            PrimaryButton(title: "Set up Dating") { showDatingSetup = true }
                .padding(.top, 8)
        }
        .padding(32)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: mode == .date ? "heart" : "figure.strengthtraining.traditional")
                .font(.system(size: 56))
            Text(vm.errorMessage ?? "You're all caught up")
                .font(.title3.bold())
                .multilineTextAlignment(.center)
            if vm.errorMessage == nil {
                Text(mode == .date
                     ? "No new people right now. Check back soon, or widen your distance in Discovery preferences."
                     : "No new people at your gym right now. Invite a friend who lifts there.")
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            Button("Refresh") { Task { await reload() } }
                .font(.headline)
                .padding(.top, 8)
        }
        .padding(32)
    }

    private func reload() async {
        if let uid = auth.userSession?.uid {
            await vm.refreshLikeStatus()
            await vm.load(userID: uid)
        }
    }
}
