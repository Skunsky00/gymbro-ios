//
//  OnboardingViewModel.swift
//  Gym Bro
//
//  Created by Jacob Johnson on 10/23/26.
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class OnboardingViewModel: ObservableObject {
    enum Step: Int, CaseIterable {
        case name, birthday, gender, trainWith, gym, schedule, style,
             experience, goal, lifts, photos, notifications, done
    }

    @Published var step: Step = .name
    @Published var firstName = ""
    @Published var birthdate = Calendar.current.date(byAdding: .year, value: -25, to: Date()) ?? Date()
    @Published var isLoaded = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedGym: Gym?
    @Published var trainWith: TrainWithPreference?
    @Published var availability: Set<String> = []
    @Published var gender: Gender?
    @Published var trainingStyles: Set<TrainingStyle> = []
    @Published var experience: ExperienceLevel?
    @Published var goal: FitnessGoal?
    @Published var benchText = ""
    @Published var squatText = ""
    @Published var deadliftText = ""
    @Published var ohpText = ""

    @Published var photoURLs: [String?] = Array(repeating: nil, count: 6)
    @Published var photoIDs: [String?] = Array(repeating: nil, count: 6)
    @Published var photoPreviews: [UIImage?] = Array(repeating: nil, count: 6)
    @Published var uploadingSlots: Set<Int> = []
    @Published var isComplete = false
    @Published var editingStep: Step?
    @Published var didFinishEditing = false

    private var userID: String?
    static let minPhotos = 3

    var uploadedPhotoCount: Int { photoURLs.compactMap { $0 }.count }
    var canContinueFromPhotos: Bool {
        uploadedPhotoCount >= Self.minPhotos && uploadingSlots.isEmpty
    }
    var primaryTitle: String { editingStep == nil ? "Next" : "Save" }


    private var user: AppUser?
    private let userService = UserService.shared

    var age: Int {
        Calendar.current.dateComponents([.year], from: birthdate, to: Date()).year ?? 0
    }
    var isNameValid: Bool {
        !firstName.trimmingCharacters(in: .whitespaces).isEmpty
    }
    var isOldEnough: Bool { age >= 18 }
    var progress: Double {
        Double(step.rawValue + 1) / Double(Step.allCases.count)
    }

    func start(userID: String) async {
        guard !isLoaded else { return }
        self.userID = userID
        do {
            var existing = try await userService.fetchUser(id: userID) ?? AppUser(id: userID)
            firstName = existing.firstName
            if let saved = existing.birthdate { birthdate = saved }
            selectedGym = existing.homeGym
            gender = existing.gender
            trainWith = existing.trainWith
            availability = Set(existing.availability ?? [])
            trainingStyles = Set(existing.trainingStyles ?? [])
            experience = existing.experience
            goal = existing.goal
            benchText = existing.lifts?.benchLb.map(String.init) ?? ""
            squatText = existing.lifts?.squatLb.map(String.init) ?? ""
            deadliftText = existing.lifts?.deadliftLb.map(String.init) ?? ""
            ohpText = existing.lifts?.overheadPressLb.map(String.init) ?? ""
            for (i, url) in (existing.photoURLs ?? []).prefix(6).enumerated() {
                photoURLs[i] = url
                photoIDs[i] = StorageService.photoID(from: url)
            }
            isComplete = existing.onboardingComplete
            step = Step(rawValue: existing.onboardingStep) ?? .name
            existing.onboardingStep = step.rawValue
            user = existing
            isLoaded = true
        } catch {
            errorMessage = "Couldn't load your profile. Check your connection."
            print("onboarding start error:", error)
        }
    }

    func next() async {
        guard var user else { return }
        errorMessage = nil
        
        switch step {
        case .name:
            user.firstName = firstName.trimmingCharacters(in: .whitespaces)
        case .birthday:
            guard isOldEnough else {
                errorMessage = "You must be 18 or older to use GymBro."
                return
            }
            user.birthdate = birthdate
        case .gym:
            guard let selectedGym else {
                errorMessage = "Pick your gym to continue."
                return
            }
            user.homeGym = selectedGym
        case .gender:
            guard let gender else {
                errorMessage = "Pick an option to continue."
                return
            }
            user.gender = gender
        case .trainWith:
            guard let trainWith else {
                errorMessage = "Pick an option to continue."
                return
            }
            user.trainWith = trainWith
        case .schedule:
            guard !availability.isEmpty else {
                errorMessage = "Pick at least one time you train."
                return
            }
            user.availability = availability.sorted()
        case .style:
            guard !trainingStyles.isEmpty else {
                errorMessage = "Pick at least one style."
                return
            }
            user.trainingStyles = trainingStyles.sorted { $0.rawValue < $1.rawValue }
        case .experience:
            guard let experience else {
                errorMessage = "Pick an option to continue."
                return
            }
            user.experience = experience
        case .goal:
            guard let goal else {
                errorMessage = "Pick an option to continue."
                return
            }
            user.goal = goal
        case .lifts:
            let bench = parsedWeight(benchText)
            let squat = parsedWeight(squatText)
            let deadlift = parsedWeight(deadliftText)
            let ohp = parsedWeight(ohpText)
            guard bench.valid, squat.valid, deadlift.valid, ohp.valid else {
                errorMessage = "Enter weights in pounds (1–1500)."
                return
            }
            if bench.value == nil && squat.value == nil && deadlift.value == nil && ohp.value == nil {
                user.lifts = nil
            } else {
                user.lifts = LiftPRs(benchLb: bench.value, squatLb: squat.value,
                                     deadliftLb: deadlift.value, overheadPressLb: ohp.value)
            }
        case .photos:
            let ids = photoIDs.compactMap { $0 }
            guard ids.count >= Self.minPhotos else {
                errorMessage = "Add at least \(Self.minPhotos) photos."
                return
            }
            isLoading = true
            do {
                user.photoURLs = try await StorageService.shared.setProfilePhotos(ids: ids)
            } catch {
                isLoading = false
                errorMessage = "Couldn't save your photos. Try again."
                print("set photos error:", error)
                return
            }
            isLoading = false
        case .notifications:
            break
        case .done:
            return
        }
        
        let nextStep = Step(rawValue: step.rawValue + 1) ?? .done
        if editingStep == nil { user.onboardingStep = nextStep.rawValue }
        user.onboardingStep = nextStep.rawValue
        
        isLoading = true
        defer { isLoading = false }
        do {
            try userService.save(user)
            self.user = user
            if editingStep != nil {
                didFinishEditing = true
            } else {
                withAnimation { step = nextStep }
            }
        } catch {
            errorMessage = "Couldn't save. Try again."
            print("onboarding save error:", error)
        }
    }

    func back() {
        guard let previous = Step(rawValue: step.rawValue - 1) else { return }
        errorMessage = nil
        withAnimation { step = previous }
    }
    
    func toggleSlot(_ key: String) {
        if availability.contains(key) {
            availability.remove(key)
        } else {
            availability.insert(key)
        }
    }
    
    func toggleStyle(_ style: TrainingStyle) {
        if trainingStyles.contains(style) {
            trainingStyles.remove(style)
        } else if trainingStyles.count < 3 {
            trainingStyles.insert(style)
        }
    }
    
    private func parsedWeight(_ text: String) -> (valid: Bool, value: Int?) {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty { return (true, nil) }
        guard let value = Int(trimmed), (1...1500).contains(value) else { return (false, nil) }
        return (true, value)
    }

    func skipLifts() async {
        benchText = ""; squatText = ""; deadliftText = ""; ohpText = ""
        await next()
    }

    func addPhoto(_ image: UIImage, slot: Int) async {
        guard let userID else { return }
        errorMessage = nil
        photoPreviews[slot] = image
        uploadingSlots.insert(slot)
        defer { uploadingSlots.remove(slot) }
        do {
            let photo = try await StorageService.shared.uploadPhoto(image, userID: userID)
            photoURLs[slot] = photo.url
            photoIDs[slot] = photo.id
        } catch PhotoUploadError.rejected {
            photoPreviews[slot] = nil
            errorMessage = "That photo doesn't meet our guidelines. Please choose a different one."
        } catch {
            photoPreviews[slot] = nil
            errorMessage = "Couldn't upload that photo. Try again."
            print("photo upload error:", error)
        }
    }

    func removePhoto(slot: Int) {
        photoURLs[slot] = nil
        photoIDs[slot] = nil
        photoPreviews[slot] = nil
    }

    func finish() async {
        guard var user else { return }
        isLoading = true
        defer { isLoading = false }
        user.onboardingComplete = true
        do {
            try userService.save(user)
            self.user = user
            isComplete = true
        } catch {
            errorMessage = "Couldn't finish. Try again."
            print("finish error:", error)
        }
    }
    
    func startEditing(_ step: Step, userID: String) async {
        await start(userID: userID)
        editingStep = step
        self.step = step
    }
}
