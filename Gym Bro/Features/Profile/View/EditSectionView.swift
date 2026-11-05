//
//  EditSectionView.swift
//  Gym Bro
//
//  Created by Jacob Johnson on 10/24/26.
//

import SwiftUI
import FirebaseAuth

extension OnboardingViewModel.Step: Identifiable {
    var id: Int { rawValue }
}

struct EditSectionView: View {
    let step: OnboardingViewModel.Step
    let onSaved: () -> Void

    @EnvironmentObject var auth: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm = OnboardingViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if vm.isLoaded { stepView } else { ProgressView() }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color.primary)
                }
            }
        }
        .environmentObject(vm)
        .task {
            if let uid = auth.userSession?.uid {
                await vm.startEditing(step, userID: uid)
            }
        }
        .onChange(of: vm.didFinishEditing) { _, finished in
            if finished {
                onSaved()
                dismiss()
            }
        }
    }

    @ViewBuilder
    private var stepView: some View {
        switch step {
        case .name: NameView()
        case .gym: GymPickerView()
        case .schedule: ScheduleView()
        case .style: TrainingStyleView()
        case .experience: ExperienceView()
        case .goal: GoalView()
        case .lifts: LiftsView()
        case .photos: PhotosView()
        default: EmptyView()
        }
    }
}
