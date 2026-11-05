//
//  SpotterFiltersView.swift
//  Gym Bro
//
//  Created by Jacob Johnson on 11/2/26.
//

import SwiftUI
import FirebaseAuth

struct SpotterFiltersView: View {
    @EnvironmentObject var auth: AuthViewModel
    @ObservedObject private var purchases = PurchaseService.shared
    @StateObject private var vm = SpotterFiltersViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showPaywall = false

    var body: some View {
        Form {
            if !purchases.isPremium {
                Section {
                    Button { showPaywall = true } label: {
                        Label("Unlock with \(Brand.premiumName)", systemImage: "lock.fill")
                    }
                    .foregroundStyle(Color.primary)
                } footer: {
                    Text("These filters only apply while you have \(Brand.premiumName).")
                }
            }

            Section("Training style") {
                ForEach(TrainingStyle.allCases, id: \.self) { style in
                    Button { vm.toggle(style) } label: {
                        HStack {
                            Text(style.title)
                            Spacer()
                            if vm.styles.contains(style) { Image(systemName: "checkmark") }
                        }
                    }
                    .foregroundStyle(Color.primary)
                }
            }
            .disabled(!purchases.isPremium)

            Section("Goal") {
                ForEach(FitnessGoal.allCases, id: \.self) { goal in
                    Button { vm.toggle(goal) } label: {
                        HStack {
                            Text(goal.title)
                            Spacer()
                            if vm.goals.contains(goal) { Image(systemName: "checkmark") }
                        }
                    }
                    .foregroundStyle(Color.primary)
                }
            }
            .disabled(!purchases.isPremium)

            Section {
                Stepper(label("Bench", vm.minBench), value: $vm.minBench, in: 0...1000, step: 25)
                Stepper(label("Squat", vm.minSquat), value: $vm.minSquat, in: 0...1000, step: 25)
                Stepper(label("Deadlift", vm.minDeadlift), value: $vm.minDeadlift, in: 0...1000, step: 25)
            } header: {
                Text("Minimum lifts")
            } footer: {
                Text("People who haven't added that lift won't match a minimum.")
            }
            .disabled(!purchases.isPremium)

            if let error = vm.errorMessage {
                Text(error).font(.footnote).foregroundStyle(.red)
            }
        }
        .navigationTitle("More filters")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    guard let uid = auth.userSession?.uid else { return }
                    Task { if await vm.save(userID: uid) { dismiss() } }
                }
                .disabled(!purchases.isPremium || !vm.isLoaded || vm.isSaving)
            }
        }
        .task {
            if let uid = auth.userSession?.uid { await vm.load(userID: uid) }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView(reason: .general)
                .presentationDetents([.medium, .large])
        }
    }

    private func label(_ name: String, _ value: Int) -> String {
        value == 0 ? "\(name): any" : "\(name): \(value) lb or more"
    }
}
