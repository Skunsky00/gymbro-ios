//
//  DatingSetupViewModel.swift
//  Gym Bro
//
//  Created by Jacob Johnson on 11/2/26.
//

import SwiftUI
import Combine

@MainActor
final class DatingSetupViewModel: ObservableObject {
    enum Screen { case intro, interest, ages }

    @Published var screen: Screen = .intro
    @Published var interestedIn: Set<Gender> = []
    @Published var minAge = 18
    @Published var maxAge = 99
    @Published var isSaving = false
    @Published var errorMessage: String?
    @Published var didFinish = false

    private let service = DatingService.shared

    var canGoBack: Bool { screen != .intro }

    func toggle(_ gender: Gender) {
        if interestedIn.contains(gender) { interestedIn.remove(gender) }
        else { interestedIn.insert(gender) }
    }

    func start() { errorMessage = nil; screen = .interest }

    func continueFromInterest() {
        guard !interestedIn.isEmpty else {
            errorMessage = "Pick at least one option."
            return
        }
        errorMessage = nil
        screen = .ages
    }

    func back() {
        errorMessage = nil
        switch screen {
        case .ages: screen = .interest
        case .interest: screen = .intro
        case .intro: break
        }
    }

    func save() async {
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }
        var prefs = DatingPrefs()
        prefs.enabled = true
        prefs.interestedIn = interestedIn
        prefs.minAge = minAge
        prefs.maxAge = maxAge
        do {
            try await service.save(prefs)
            didFinish = true
        } catch {
            errorMessage = DatingService.message(for: error)
        }
    }
}
