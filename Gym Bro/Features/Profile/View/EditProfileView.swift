//
//  EditProfileView.swift
//  Gym Bro
//
//  Created by Jacob Johnson on 11/2/26.
//

import SwiftUI
import FirebaseAuth

struct EditProfileView: View {
    enum Page: Hashable { case edit, view }

    @EnvironmentObject var auth: AuthViewModel
    @StateObject private var vm = ProfileViewModel()
    @State private var page: Page? = .edit
    @State private var editingStep: OnboardingViewModel.Step?
    @State private var showCaption = false
    var onChanged: () -> Void = {}

    var body: some View {
        Group {
            if let user = vm.user {
                GeometryReader { geo in
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 0) {
                            editPage(user)
                                .frame(width: geo.size.width, height: geo.size.height)
                                .id(Page.edit)
                            viewPage(user)
                                .frame(width: geo.size.width, height: geo.size.height)
                                .id(Page.view)
                        }
                        .scrollTargetLayout()
                    }
                    .scrollTargetBehavior(.paging)
                    .scrollPosition(id: $page)
                }
            } else if vm.isLoading {
                ProgressView()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Picker("Page", selection: pageBinding) {
                    Text("Edit").tag(Page.edit)
                    Text("View").tag(Page.view)
                }
                .pickerStyle(.segmented)
                .frame(width: 180)
            }
        }
        .task { await reload() }
        .sheet(item: $editingStep) { step in
            EditSectionView(step: step) {
                Task { await reload(); onChanged() }
            }
        }
        .sheet(isPresented: $showCaption) {
            if let uid = auth.userSession?.uid {
                CaptionEditView(uid: uid, initial: vm.user?.caption ?? "") {
                    Task { await reload(); onChanged() }
                }
                .presentationDetents([.medium])
            }
        }
    }

    // MARK: - Pages

    private func editPage(_ user: AppUser) -> some View {
        let caption = user.caption ?? ""
        return List {
            Section {
                Button { showCaption = true } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Caption").foregroundStyle(Color.primary)
                            Text(caption.isEmpty ? "Add a short line about you" : caption)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.footnote.bold())
                            .foregroundStyle(.tertiary)
                    }
                }
            }

            Section("Your profile") {
                row("Photos", "\(user.photoURLs?.count ?? 0) photos", .photos)
                row("Name", user.firstName, .name)
                row("Gym", user.homeGym?.name ?? "Not set", .gym)
                row("Schedule", "\(user.availability?.count ?? 0) time slots", .schedule)
                row("Training style",
                    (user.trainingStyles ?? []).map(\.title).joined(separator: ", "),
                    .style)
                row("Experience", user.experience?.title ?? "Not set", .experience)
                row("Goal", user.goal?.title ?? "Not set", .goal)
                row("Lifts", liftSummary(user.lifts), .lifts)
            }
        }
    }

    private func viewPage(_ user: AppUser) -> some View {
        ScrollView {
            ProfileCardView(user: user, overlap: nil)
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 24)
        }
    }

    private func row(_ title: String, _ value: String,
                     _ step: OnboardingViewModel.Step) -> some View {
        Button { editingStep = step } label: {
            HStack {
                Text(title).foregroundStyle(Color.primary)
                Spacer()
                Text(value).foregroundStyle(.secondary).lineLimit(1)
                Image(systemName: "chevron.right")
                    .font(.footnote.bold())
                    .foregroundStyle(.tertiary)
            }
        }
    }

    private func liftSummary(_ lifts: LiftPRs?) -> String {
        guard let lifts else { return "Not set" }
        let count = [lifts.benchLb, lifts.squatLb, lifts.deadliftLb, lifts.overheadPressLb]
            .compactMap { $0 }.count
        return count == 0 ? "Not set" : "\(count) lifts"
    }

    // MARK: - Actions

    private var pageBinding: Binding<Page> {
        Binding(
            get: { page ?? .edit },
            set: { newValue in withAnimation { page = newValue } }
        )
    }

    private func reload() async {
        if let uid = auth.userSession?.uid { await vm.load(userID: uid) }
    }

    private func saveCaption(_ text: String) async -> Bool {
        guard let uid = auth.userSession?.uid else { return false }
        do {
            try await UserService.shared.updateCaption(uid: uid, caption: text)
            await reload()
            onChanged()
            return true
        } catch {
            print("caption save error:", error)
            return false
        }
    }
}
