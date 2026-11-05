//
//  GymPickerView.swift
//  Gym Bro
//
//  Created by Jacob Johnson on 10/23/26.
//

import SwiftUI
internal import CoreLocation

struct GymPickerView: View {
    @EnvironmentObject var vm: OnboardingViewModel
    @StateObject private var picker = GymPickerViewModel()
    @StateObject private var location = LocationService()

    private var locationDenied: Bool {
        location.status == .denied || location.status == .restricted
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Where do you train?")
                .font(.largeTitle.bold())
            Text("Pick your home gym. We use it to match you with people you'll actually run into.")
                .foregroundStyle(.secondary)

            HStack {
                Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                TextField("Search gyms", text: $picker.query)
                    .autocorrectionDisabled()
                if !picker.query.isEmpty {
                    Button { picker.query = "" } label: {
                        Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                    }
                }
            }
            .padding(12)
            .background(.quaternary, in: RoundedRectangle(cornerRadius: 12))

            if locationDenied {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Location is off. Search by gym name and city, like \"Planet Fitness Tampa\", or turn it on in Settings.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Button("Open Settings") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                    .font(.footnote.bold())
                }
            }

            ScrollView {
                LazyVStack(spacing: 8) {
                    if picker.isSearching && picker.results.isEmpty {
                        ProgressView().padding(.top, 24)
                    }
                    ForEach(picker.results) { gym in
                        GymRow(gym: gym,
                               miles: picker.distanceMiles(to: gym),
                               isSelected: vm.selectedGym?.id == gym.id)
                            .onTapGesture { vm.selectedGym = gym }
                    }
                    if !picker.isSearching && picker.results.isEmpty
                        && (picker.userLocation != nil || !picker.query.isEmpty) {
                        Text("No gyms found. Try a different name.")
                            .foregroundStyle(.secondary)
                            .padding(.top, 24)
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)

            if let error = picker.errorMessage ?? vm.errorMessage {
                Text(error).foregroundStyle(.red).font(.footnote)
            }

            PrimaryButton(title: vm.primaryTitle,
                          isLoading: vm.isLoading,
                          isEnabled: vm.selectedGym != nil) {
                Task { await vm.next() }
            }
        }
        .padding(24)
        .onAppear { location.request() }
        .onChange(of: location.location) { _, newValue in
            if let newValue { picker.updateLocation(newValue) }
        }
        .onChange(of: picker.query) { _, _ in
            picker.scheduleSearch()
        }
    }
}

struct GymRow: View {
    let gym: Gym
    let miles: Double?
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(gym.name).font(.headline)
                Text(gym.address)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer()
            if let miles {
                Text(String(format: "%.1f mi", miles))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
            }
        }
        .padding(12)
        .background(isSelected ? Color.primary.opacity(0.12) : Color.primary.opacity(0.04),
                    in: RoundedRectangle(cornerRadius: 12))
        .contentShape(Rectangle())
    }
}
