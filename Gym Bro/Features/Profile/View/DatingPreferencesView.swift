//
//  DatingPreferencesView.swift
//  Gym Bro
//
//  Created by Jacob Johnson on 11/2/26.
//

import SwiftUI

struct DatingPreferencesView: View {
    @StateObject private var vm = DatingPreferencesViewModel()
    @ObservedObject private var purchases = PurchaseService.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showSetup = false

    var body: some View {
        Group {
            if vm.isLoading {
                ProgressView()
            } else if !vm.hasSetUp && vm.errorMessage != nil {
                VStack(spacing: 12) {
                    Text(vm.errorMessage ?? "").multilineTextAlignment(.center)
                    Button("Try again") { Task { await vm.load() } }
                        .font(.headline)
                }
                .padding(32)
            } else if !vm.hasSetUp {
                VStack(spacing: 14) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(Color.dateAccent)
                    Text("Dating isn't on yet").font(.title3.bold())
                    Text("Set it up to meet people at your gym who want to go out.")
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    PrimaryButton(title: "Set up Dating") { showSetup = true }
                }
                .padding(32)
            } else {
                form
            }
        }
        .navigationTitle("Dating preferences")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // Use .confirmationAction for standard top-right, or .topBarLeading for top-left
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    Task {
                        if await vm.save() {
                            dismiss()
                        }
                    }
                }
                .disabled(!vm.canSave)
            }
        }
        .task { await vm.load() }
        .sheet(isPresented: $showSetup) {
            DatingSetupView { Task { await vm.load() } }
        }
    }

    private var form: some View {
        Form {
            Section {
                Toggle("Show me in Dating", isOn: $vm.isEnabled)
            } footer: {
                Text("Turn this off to hide yourself from the Date feed. Your existing date matches stay until you unmatch.")
            }

            Section {
                ForEach(Gender.allCases, id: \.self) { gender in
                    Button { vm.toggle(gender) } label: {
                        HStack {
                            Text(gender.interestTitle).foregroundStyle(Color.primary)
                            Spacer()
                            if vm.interestedIn.contains(gender) {
                                Image(systemName: "checkmark").foregroundStyle(Color.primary)
                            }
                        }
                    }
                }
            } header: {
                Text("Who do you want to meet?")
            } footer: {
                Text("Only used to match you. Nobody else can see it.")
            }
            .disabled(!vm.isEnabled)

            Section("Age range") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("\(vm.minAge) – \(vm.maxAge)")
                        .font(.headline)
                    RangeSlider(lower: $vm.minAge, upper: $vm.maxAge, bounds: 18...99)
                }
                .padding(.vertical, 4)
            }
            .disabled(!vm.isEnabled)
            
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text(vm.radiusLabel).font(.headline)
                    Slider(value: $vm.radiusIndex,
                           in: 0...Double(DiscoveryPrefs.radiusOptions.count - 1),
                           step: 1)
                        .tint(Color.primary)
                }
                .padding(.vertical, 4)
            } header: {
                Text("Distance")
            } footer: {
                if !purchases.isPremium
                    && Int(vm.radiusIndex) >= DiscoveryPrefs.radiusOptions.count - 1 {
                    Text("Free accounts search up to \(DiscoveryPrefs.freeRadiusLimit) miles. \(Brand.premiumName) unlocks 50.")
                }
            }
            .disabled(!vm.isEnabled)

            if let error = vm.errorMessage {
                Text(error).font(.footnote).foregroundStyle(.red)
            }
        }
    }
}
