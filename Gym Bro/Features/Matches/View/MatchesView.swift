//
//  MatchesView.swift
//  Gym Bro
//
//  Created by Jacob Johnson on 10/23/26.
//

import SwiftUI
import FirebaseAuth

struct MatchesView: View {
    @EnvironmentObject var auth: AuthViewModel
    @ObservedObject private var router = AppRouter.shared
    @StateObject private var vm = MatchesViewModel()
    @State private var deepLinked: MatchesViewModel.Row?

    private var myID: String { auth.userSession?.uid ?? "" }

    var body: some View {
        NavigationStack {
            Group {
                if vm.isLoading {
                    ProgressView()
                } else if vm.rows.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "bubble.left.and.bubble.right")
                            .font(.system(size: 48))
                        Text("No matches yet").font(.title3.bold())
                        Text("Like people on Discover. When it's mutual, you'll chat here.")
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(32)
                } else {
                    List {
                        if FeatureFlags.dating && vm.hasDateMatches {
                            ModeFilterPicker(filter: $vm.filter)
                                .listRowSeparator(.hidden)
                        }
                        if vm.newRows.isEmpty && vm.conversationRows.isEmpty {
                            Text("No \(vm.filter.title.lowercased()) matches yet")
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity)
                                .listRowSeparator(.hidden)
                        }
                        if !vm.newRows.isEmpty {
                            Section {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 16) {
                                        ForEach(vm.newRows) { row in
                                            NavigationLink {
                                                ChatView(match: row.match, other: row.user,
                                                         myID: myID, myGym: vm.myGym)
                                            } label: {
                                                NewMatchTile(row: row,
                                                             isUnread: row.match.isUnread(for: myID))
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                }
                                .listRowInsets(EdgeInsets())
                                .listRowSeparator(.hidden)
                            } header: {
                                Text("New Matches")
                                    .font(.subheadline.bold())
                                    .foregroundStyle(.primary)
                                    .textCase(nil)
                            }
                        }

                        if !vm.conversationRows.isEmpty {
                            Section {
                                ForEach(vm.conversationRows) { row in
                                    NavigationLink {
                                        ChatView(match: row.match, other: row.user,
                                                 myID: myID, myGym: vm.myGym)
                                    } label: {
                                        MatchRow(row: row,
                                                 isUnread: row.match.isUnread(for: myID))
                                    }
                                }
                            } header: {
                                Text("Messages")
                                    .font(.subheadline.bold())
                                    .foregroundStyle(.primary)
                                    .textCase(nil)
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Matches")
            .navigationDestination(item: $deepLinked) { row in
                ChatView(match: row.match, other: row.user, myID: myID, myGym: vm.myGym)
            }
        }
        .onAppear {
            if let uid = auth.userSession?.uid { vm.start(userID: uid) }
            openPendingChat()
        }
        .onDisappear {
            vm.stop()
            router.pendingMatchID = nil
        }
        .onChange(of: router.pendingMatchID) { _, _ in openPendingChat() }
        .onChange(of: vm.rows.count) { _, _ in openPendingChat() }
        .onChange(of: vm.isLoading) { _, _ in openPendingChat() }
    }

    /// Opens the chat a tapped push points at, once the match list has loaded.
    private func openPendingChat() {
        guard let id = router.pendingMatchID, !vm.isLoading,
              let row = vm.rows.first(where: { $0.id == id }) else { return }
        deepLinked = row
        router.pendingMatchID = nil
    }
}

extension MatchesViewModel.Row: Hashable {
    static func == (lhs: Self, rhs: Self) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

struct MatchRow: View {
    let row: MatchesViewModel.Row
    let isUnread: Bool

    var body: some View {
        HStack(spacing: 12) {
            Avatar(urlString: row.user.photoURLs?.first)
                .overlay(Circle().stroke(row.match.mode == .date ? Color.dateAccent : Color.clear,
                                         lineWidth: 2))
                .overlay(alignment: .bottomTrailing) {
                    if row.match.mode == .date { DateHeartBadge(size: 18) }
                }
            VStack(alignment: .leading, spacing: 2) {
                Text(row.user.firstName).font(.headline)
                Text(row.match.lastMessage ?? "New match. Say hi!")
                    .font(.subheadline)
                    .fontWeight(isUnread ? .semibold : .regular)
                    .foregroundStyle(isUnread ? Color.primary : Color.secondary)
                    .lineLimit(1)
            }
            Spacer()
            if isUnread {
                Circle().fill(Color.primary).frame(width: 10, height: 10)
            }
        }
        .padding(.vertical, 4)
    }
}

struct Avatar: View {
    let urlString: String?
    var size: CGFloat = 52

    var body: some View {
        AsyncImage(url: urlString.flatMap { URL(string: $0) }) { phase in
            if let image = phase.image {
                image.resizable().scaledToFill()
            } else {
                Color.primary.opacity(0.1)
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }
}

struct NewMatchTile: View {
    let row: MatchesViewModel.Row
    let isUnread: Bool

    var body: some View {
        VStack(spacing: 6) {
            Avatar(urlString: row.user.photoURLs?.first, size: 72)
                .padding(3)
                .overlay(Circle().stroke(row.match.mode == .date ? Color.dateAccent : Color.primary,
                                         lineWidth: 2))
                .overlay(alignment: .topTrailing) {
                    if isUnread {
                        Circle()
                            .fill(Color.primary)
                            .frame(width: 14, height: 14)
                            .overlay(Circle().stroke(Color(.systemBackground), lineWidth: 2))
                    }
                }
                .overlay(alignment: .bottomTrailing) {
                    if row.match.mode == .date { DateHeartBadge(size: 22) }
                }
            Text(row.user.firstName)
                .font(.caption.bold())
                .lineLimit(1)
        }
        .frame(width: 80)
    }
}
