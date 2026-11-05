//
//  DiscoveryPreferencesView.swift
//  Gym Bro
//
//  Created by Jacob Johnson on 10/24/26.
//

import SwiftUI
import FirebaseAuth

struct DiscoveryPreferencesView: View {
    @EnvironmentObject var auth: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm = PreferencesViewModel()
    @ObservedObject private var purchases = PurchaseService.shared

    var body: some View {
        Group {
            if vm.isLoaded {
                Form {
                    Section("Train with") {
                        Picker("Train with", selection: $vm.trainWith) {
                            ForEach(TrainWithPreference.allCases, id: \.self) {
                                Text($0.title).tag($0)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    
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

                    Section("Age range") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("\(vm.minAge) – \(vm.maxAge)")
                                .font(.headline)
                            RangeSlider(lower: $vm.minAge, upper: $vm.maxAge, bounds: 18...99)
                        }
                        .padding(.vertical, 4)
                    }

                    Section {
                        ForEach(ExperienceLevel.allCases, id: \.self) { level in
                            Button { vm.toggleExperience(level) } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(level.title)
                                        Text(level.subtitle)
                                            .font(.footnote)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    if vm.experience.contains(level) {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                            .foregroundStyle(Color.primary)
                        }
                    } header: {
                        Text("Experience level")
                    } footer: {
                        Text("Leave all unselected to see everyone.")
                    }

                    Section {
                        Toggle("Only people whose schedule overlaps mine", isOn: $vm.requireOverlap)
                    }
                    
                    Section {
                        NavigationLink {
                            SpotterFiltersView()
                        } label: {
                            HStack {
                                Text("More filters")
                                Spacer()
                                Text(Brand.premiumName).font(.footnote.bold()).foregroundStyle(.secondary)
                            }
                        }
                    }

                    if let error = vm.errorMessage {
                        Text(error).foregroundStyle(.red).font(.footnote)
                    }
                }
            } else if let error = vm.errorMessage {
                Text(error).foregroundStyle(.secondary)
            } else {
                ProgressView()
            }
        }
        .navigationTitle("Preferences")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    Task { if await vm.save() { dismiss() } }
                }
                .disabled(!vm.isLoaded || vm.isSaving)
            }
        }
        .task {
            if let uid = auth.userSession?.uid {
                await vm.load(userID: uid)
            }
        }
    }
}
