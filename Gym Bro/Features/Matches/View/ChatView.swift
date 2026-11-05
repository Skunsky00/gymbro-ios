//
//  ChatView.swift
//  Gym Bro
//
//  Created by Jacob Johnson on 10/23/26.
//

import SwiftUI
import UIKit

struct ChatView: View {
    enum Page: Hashable { case chat, profile }

    @StateObject private var vm: ChatViewModel
    private let matchID: String
    @State private var page: Page? = .chat
    @State private var myUser: AppUser?
    @State private var showPropose = false
    @Environment(\.dismiss) private var dismiss

    init(match: Match, other: AppUser, myID: String, myGym: Gym?) {
        matchID = match.id
        _vm = StateObject(wrappedValue: ChatViewModel(match: match, other: other,
                                                      myID: myID, myGym: myGym))
    }

    var body: some View {
        GeometryReader { geo in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    chatPage
                        .frame(width: geo.size.width)
                        .id(Page.chat)
                    profilePage
                        .frame(width: geo.size.width)
                        .id(Page.profile)
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.paging)
            .scrollPosition(id: $page)
        }
        .navigationTitle(vm.other.firstName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Picker("Page", selection: pageBinding) {
                    Text("Chat").tag(Page.chat)
                    Text("Profile").tag(Page.profile)
                }
                .pickerStyle(.segmented)
                .frame(width: 200)
            }
            ToolbarItem(placement: .topBarTrailing) {
                SafetyMenu(
                    name: vm.other.firstName,
                    onUnmatch: {
                        await vm.unmatch()
                        if vm.isEnded { dismiss() }
                    },
                    onBlock: {
                        await vm.block()
                        if vm.isEnded { dismiss() }
                    },
                    onReport: { reason, details, alsoBlock in
                        await vm.report(reason: reason, details: details, alsoBlock: alsoBlock)
                    }
                )
            }
        }
        .onAppear {
            vm.start()
            AppRouter.shared.activeChatMatchID = matchID
            markRead()
        }
        .onDisappear {
            vm.stop()
            if AppRouter.shared.activeChatMatchID == matchID {
                AppRouter.shared.activeChatMatchID = nil
            }
        }
        .onChange(of: vm.messages.count) { _, _ in markRead() }
        .onChange(of: page) { _, newPage in
            if newPage == .profile { hideKeyboard() }
        }
        .task {
            myUser = try? await UserService.shared.fetchUser(id: vm.myID)
        }
        .sheet(isPresented: $showPropose) {
            ProposeSessionView(myGym: vm.myGym,
                               theirGym: vm.other.homeGym,
                               theirName: vm.other.firstName) { date, focus, place in
                Task { await vm.propose(startTime: date, focus: focus, gymName: place) }
            }
            .presentationDetents([.large])
        }
    }

    // MARK: - Pages

    private var chatPage: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(vm.messages) { message in
                            MessageRow(
                                message: message,
                                isMine: message.senderID == vm.myID,
                                otherName: vm.other.firstName,
                                gymName: vm.other.homeGym?.name,
                                onRespond: { accept in
                                    Task { await vm.respond(to: message, accept: accept) }
                                }
                            )
                            .id(message.id)
                        }
                    }
                    .padding()
                }
                .scrollDismissesKeyboard(.interactively)
                .onChange(of: vm.messages.count) { _, _ in
                    if let last = vm.messages.last {
                        withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                    }
                }
            }

            if let error = vm.errorMessage {
                Text(error).foregroundStyle(.red).font(.footnote).padding(.bottom, 4)
            }

            if vm.isEnded {
                Text("This conversation has ended.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.bar)
            } else {
                inputBar
            }
        }
    }

    private var profilePage: some View {
        ScrollView {
            ProfileCardView(user: vm.other,
                            overlap: overlap,
                            gymNote: gymNote)
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 24)
        }
    }

    // MARK: - Profile helpers

    private var overlap: [String] {
        ScheduleOverlap.shared(myUser?.availability, vm.other.availability)
    }

    private var gymNote: String? {
        guard let myGym = vm.myGym, let theirGym = vm.other.homeGym else { return nil }
        if theirGym.id == myGym.id { return "Your gym" }
        let miles = myGym.distanceMiles(to: theirGym)
        if miles < 0.1 { return "Next door to your gym" }
        return String(format: "%.1f mi from your gym", miles)
    }

    private var pageBinding: Binding<Page> {
        Binding(
            get: { page ?? .chat },
            set: { newValue in withAnimation { page = newValue } }
        )
    }

    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                        to: nil, from: nil, for: nil)
    }

    private func markRead() {
        let uid = vm.myID
        Task { await MatchService.shared.markRead(matchID: matchID, userID: uid) }
    }

    // MARK: - Input bar

    private var inputBar: some View {
        HStack(spacing: 10) {
            Button { showPropose = true } label: {
                Image(systemName: "calendar.badge.plus").font(.title2)
            }
            .foregroundStyle(Color.primary)

            TextField("Message", text: $vm.draft, axis: .vertical)
                .lineLimit(1...4)
                .padding(10)
                .background(Color.primary.opacity(0.06), in: RoundedRectangle(cornerRadius: 18))

            Button { Task { await vm.send() } } label: {
                Image(systemName: "arrow.up.circle.fill").font(.title)
            }
            .foregroundStyle(Color.primary)
            .disabled(!vm.canSend)
            .opacity(vm.canSend ? 1 : 0.35)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.bar)
    }
}

struct MessageRow: View {
    let message: ChatMessage
    let isMine: Bool
    let otherName: String
    let gymName: String?
    let onRespond: (Bool) -> Void

    var body: some View {
        HStack {
            if isMine { Spacer(minLength: 48) }
            content
            if !isMine { Spacer(minLength: 48) }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch message.content {
        case .text(let text):
            Text(text)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(isMine ? Color.primary : Color.primary.opacity(0.08),
                            in: RoundedRectangle(cornerRadius: 18))
                .foregroundStyle(isMine ? Color(.systemBackground) : Color.primary)
        case .session(let session):
            SessionCard(session: session,
                        isMine: isMine,
                        otherName: otherName,
                        gymName: gymName,
                        onRespond: onRespond)
        }
    }
}
