//
//  LikesView.swift
//  Gym Bro
//
//  Created by Jacob Johnson on 10/30/26.
//

import SwiftUI
import FirebaseAuth

struct LikesView: View {
    @EnvironmentObject var auth: AuthViewModel
    @StateObject private var vm = LikesViewModel()
    @State private var selected: IncomingLike?
    @ObservedObject private var purchases = PurchaseService.shared

    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Likes")
                .safeAreaInset(edge: .bottom) {
                    if vm.hasLoaded && !vm.isPremium { upgradeButton }
                }
                .sheet(item: $vm.paywallReason) { reason in
                    PaywallView(reason: reason)
                        .presentationDetents([.medium, .large])
                }
        }
        .onAppear { Task { await reload() } }
        .onChange(of: purchases.isPremium) { _, _ in Task { await reload() } }
        .sheet(item: $selected) { item in
            LikeDetailView(
                item: item,
                onLikeBack: { selected = nil; Task { await vm.likeBack(item) } },
                onPass: { selected = nil; Task { await vm.pass(item) } },
                onBlock: { selected = nil; await vm.block(item) },
                onReport: { reason, details, alsoBlock in
                    selected = nil
                    await vm.report(item, reason: reason, details: details, alsoBlock: alsoBlock)
                }
            )
        }
        .sheet(item: $vm.newMatch) { MatchView(user: $0, mode: vm.newMatchMode) }
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        if !vm.hasLoaded && vm.errorMessage == nil {
            ProgressView()
        } else if vm.isPremium && !vm.visibleItems.isEmpty {
            ScrollView {
                filterBar
                header(count: vm.visibleItems.count, locked: false)
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(vm.visibleItems) { item in
                        Button { selected = item } label: { LikeCard(item: item) }
                            .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 16)
            }
            .refreshable { await reload() }
        } else if !vm.isPremium && vm.visibleLockedCount > 0 {
            ScrollView {
                filterBar
                header(count: vm.visibleLockedCount, locked: true)
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(0..<min(vm.visibleLockedCount, 30), id: \.self) { _ in
                        Button { vm.paywallReason = .seeWhoLikesYou } label: { LockedLikeCard() }
                            .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 16)
            }
            .refreshable { await reload() }
        } else {
            VStack(spacing: 0) {
                filterBar
                emptyState
            }
        }
    }

    @ViewBuilder
    private var filterBar: some View {
        if FeatureFlags.dating && vm.hasAnyLikes {
            ModeFilterPicker(filter: $vm.filter)
                .padding(.horizontal)
                .padding(.top, 8)
        }
    }

    private func header(count: Int, locked: Bool) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(count == 1 ? "1 person likes you" : "\(count) people like you")
                .font(.title3.bold())
            if locked {
                Text("Upgrade to see who they are and like them back.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
        .padding(.top, 8)
        .padding(.bottom, 12)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "heart")
                .font(.system(size: 48))
            Text(vm.errorMessage ?? "No likes yet").font(.title3.bold())
            if vm.errorMessage == nil {
                Text("When someone likes your profile, they'll show up here.")
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            Button("Refresh") { Task { await reload() } }
                .font(.headline)
                .padding(.top, 8)
        }
        .padding(32)
    }

    private var upgradeButton: some View {
        Button { vm.paywallReason = .seeWhoLikesYou } label: {
            Text(vm.lockedTrain + vm.lockedDate > 0
                 ? "See everyone who likes you"
                 : "Get unlimited likes")
                .font(.headline)
                .foregroundStyle(Color(.systemBackground))
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(Color.primary, in: Capsule())
                .shadow(color: .black.opacity(0.18), radius: 8, y: 3)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }

    private func reload() async {
        if let uid = auth.userSession?.uid { await vm.load(userID: uid) }
    }
}

struct LockedLikeCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Color.clear
                .aspectRatio(3 / 4, contentMode: .fit)
                .overlay {
                    ZStack {
                        LinearGradient(colors: [Color.primary.opacity(0.14), Color.primary.opacity(0.05)],
                                       startPoint: .top, endPoint: .bottom)
                        Image(systemName: "person.fill")
                            .font(.system(size: 64))
                            .foregroundStyle(Color.primary.opacity(0.2))
                            .blur(radius: 6)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay {
                    Image(systemName: "lock.fill")
                        .font(.title2)
                        .foregroundStyle(Color.primary.opacity(0.6))
                }
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.primary.opacity(0.1))
                .frame(width: 70, height: 12)
        }
    }
}

struct LikeCard: View {
    let item: IncomingLike

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Color.clear
                .aspectRatio(3 / 4, contentMode: .fit)
                .overlay {
                    AsyncImage(url: URL(string: item.user.photoURLs?.first ?? "")) { phase in
                        if let image = phase.image {
                            image.resizable().scaledToFill()
                        } else {
                            Color.primary.opacity(0.08)
                        }
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(item.mode == .date ? Color.dateAccent : Color.clear, lineWidth: 3)
                )
                .overlay(alignment: .topLeading) {
                    if item.mode == .date { DateHeartBadge(size: 26).padding(8) }
                }
                .overlay(alignment: .bottomTrailing) {
                    if item.photoURL != nil {
                        Image(systemName: item.comment != nil ? "text.bubble.fill" : "photo")
                            .font(.footnote)
                            .foregroundStyle(Color(.systemBackground))
                            .frame(width: 28, height: 28)
                            .background(Color.primary, in: Circle())
                            .padding(8)
                    }
                }

            Text("\(item.user.firstName)\(item.user.age.map { ", \($0)" } ?? "")")
                .font(.headline)
        }
    }
}

struct LikeDetailView: View {
    let item: IncomingLike
    let onLikeBack: () -> Void
    let onPass: () -> Void
    let onBlock: () async -> Void
    let onReport: (ReportReason, String, Bool) async -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 10) {
                    if item.mode == .date {
                        Label("Date", systemImage: "heart.fill")
                            .font(.footnote.bold())
                            .foregroundStyle(Color.dateAccent)
                    }
                    if let liked = item.photoURL {
                        Text("\(item.user.firstName) liked your photo")
                            .font(.footnote.bold())
                            .foregroundStyle(.secondary)

                        RemotePhoto(urlString: liked)
                            .overlay(alignment: .bottom) {
                                if let comment = item.comment {
                                    Text(comment)
                                        .font(.headline)
                                        .foregroundStyle(Color.primary)
                                        .multilineTextAlignment(.leading)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(14)
                                        .background(.regularMaterial,
                                                    in: RoundedRectangle(cornerRadius: 14))
                                        .padding(12)
                                }
                            }
                    } else {
                        Text("\(item.user.firstName) liked you")
                            .font(.footnote.bold())
                            .foregroundStyle(.secondary)
                    }
                }

                ProfileCardView(user: item.user, overlap: nil)
            }
            .padding(.horizontal, 20)
            .padding(.top, 56)
            .padding(.bottom, 24)
        }
        .safeAreaInset(edge: .bottom) { actionBar }
        .overlay(alignment: .topTrailing) {
            SafetyMenu(
                name: item.user.firstName,
                onPhoto: true,
                onBlock: onBlock,
                onReport: onReport
            )
            .padding(.trailing, 28)
            .padding(.top, 16)
        }
    }

    private var actionBar: some View {
        HStack(spacing: 40) {
            Button(action: onPass) {
                Image(systemName: "xmark")
                    .font(.title2.bold())
                    .foregroundStyle(Color.primary)
                    .frame(width: 64, height: 64)
                    .background(Color.primary.opacity(0.1), in: Circle())
            }
            Button(action: onLikeBack) {
                Image(systemName: "heart.fill")
                    .font(.title2)
                    .foregroundStyle(Color(.systemBackground))
                    .frame(width: 64, height: 64)
                    .background(Color.primary, in: Circle())
            }
        }
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(.bar)
    }
}
