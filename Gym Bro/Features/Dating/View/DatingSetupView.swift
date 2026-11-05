//
//  DatingSetupView.swift
//  Gym Bro
//
//  Created by Jacob Johnson on 11/2/26.
//

import SwiftUI

struct DatingSetupView: View {
    @StateObject private var vm = DatingSetupViewModel()
    @Environment(\.dismiss) private var dismiss
    var onFinished: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                if vm.canGoBack {
                    Button { vm.back() } label: {
                        Image(systemName: "chevron.left").font(.title3.bold())
                    }
                    .foregroundStyle(Color.primary)
                }
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark").font(.title3.bold())
                }
                .foregroundStyle(Color.primary)
            }

            switch vm.screen {
            case .intro: intro
            case .interest: interest
            case .ages: ages
            }

            if let error = vm.errorMessage {
                Text(error).font(.footnote).foregroundStyle(.red)
            }
        }
        .padding(24)
        .onChange(of: vm.didFinish) { _, done in
            if done { onFinished(); dismiss() }
        }
    }

    private var intro: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Gym dates").font(.largeTitle.bold())
            Text("Turn on Dating to meet people at your gym, and nearby gyms, who you might want to go out with.")
                .foregroundStyle(.secondary)
            Label("Uses your existing profile and photos", systemImage: "person.crop.square")
            Label("Who you want to meet stays private. Other people can't see it.",
                  systemImage: "lock.fill")
            Label("Dating matches are kept separate from your gym partners.",
                  systemImage: "heart")
            Label("You can change this any time in Profile.", systemImage: "slider.horizontal.3")
            Spacer()
            PrimaryButton(title: "Get started") { vm.start() }
        }
    }

    private var interest: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Who do you want to meet?").font(.largeTitle.bold())
            Text("Pick all that apply. It's only used to match you, and nobody else can see it.")
                .foregroundStyle(.secondary)
            ForEach(Gender.allCases, id: \.self) { gender in
                Button { vm.toggle(gender) } label: {
                    HStack {
                        Text(gender.interestTitle).font(.headline)
                        Spacer()
                        Image(systemName: vm.interestedIn.contains(gender)
                              ? "checkmark.circle.fill" : "circle")
                    }
                    .foregroundStyle(Color.primary)
                    .padding(16)
                    .background(Color.primary.opacity(0.06),
                                in: RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(vm.interestedIn.contains(gender)
                                    ? Color.primary : Color.clear, lineWidth: 2)
                    )
                }
            }
            Spacer()
            PrimaryButton(title: "Next") { vm.continueFromInterest() }
        }
    }

    private var ages: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Age range").font(.largeTitle.bold())
            Text("This is separate from your gym partner preferences.")
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 8) {
                Text("\(vm.minAge) – \(vm.maxAge)")
                    .font(.headline)
                RangeSlider(lower: $vm.minAge, upper: $vm.maxAge, bounds: 18...99)
            }
            .padding(.vertical, 4)
            Spacer()
            PrimaryButton(title: "Turn on Dating",
                          isLoading: vm.isSaving,
                          isEnabled: !vm.isSaving) {
                Task { await vm.save() }
            }
        }
    }
}
