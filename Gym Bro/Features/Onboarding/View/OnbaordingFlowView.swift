//
//  OnbaordingFlowView.swift
//  Gym Bro
//
//  Created by Jacob Johnson on 10/23/26.
//

// OnboardingFlowView.swift
import SwiftUI
import FirebaseAuth

struct OnboardingFlowView: View {
    @EnvironmentObject var auth: AuthViewModel
    @StateObject private var vm = OnboardingViewModel()

    var body: some View {
        Group {
            if !vm.isLoaded {
                ProgressView()
            } else if vm.isComplete {
               MainTabView()
            } else {
                VStack(spacing: 0) {
                    if vm.step != .done { header }
                    stepView
                }
            }
        }
        .environmentObject(vm)
        .task {
            if let uid = auth.userSession?.uid {
                await vm.start(userID: uid)
            }
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            if vm.step.rawValue > 0 {
                Button { vm.back() } label: {
                    Image(systemName: "chevron.left").font(.headline)
                }
                .foregroundStyle(.primary)
            }
            ProgressView(value: vm.progress).tint(.primary)
        }
        .padding(.horizontal, 24)
        .padding(.top, 8)
    }

    @ViewBuilder
    private var stepView: some View {
        switch vm.step {
        case .name: NameView()
        case .birthday: BirthdayView()
        case .gender: GenderView()
        case .trainWith: TrainWithView()
        case .gym: GymPickerView()
        case .schedule: ScheduleView()
        case .style: TrainingStyleView()
        case .experience: ExperienceView()
        case .goal: GoalView()
        case .lifts: LiftsView()
        case .photos: PhotosView()
        case .notifications: NotificationsPromptView()
        case .done: DoneView()
        }
    }
}

// NameView.swift
struct NameView: View {
    @EnvironmentObject var vm: OnboardingViewModel
    @FocusState private var focused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("What's your first name?")
                .font(.largeTitle.bold())

            TextField("First name", text: $vm.firstName)
                .textContentType(.givenName)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .focused($focused)
                .font(.title2)
            Divider()

            if let error = vm.errorMessage {
                Text(error).foregroundStyle(.red).font(.footnote)
            }

            Spacer()

            PrimaryButton(title: vm.primaryTitle, isLoading: vm.isLoading, isEnabled: vm.isNameValid) {
                Task { await vm.next() }
            }
        }
        .padding(24)
        .onAppear { focused = true }
    }
}

// BirthdayView.swift
struct BirthdayView: View {
    @EnvironmentObject var vm: OnboardingViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("When's your birthday?")
                .font(.largeTitle.bold())
            Text("You'll show as \(vm.age) on your profile.")
                .foregroundStyle(.secondary)

            DatePicker("", selection: $vm.birthdate,
                       in: ...Date(), displayedComponents: .date)
                .datePickerStyle(.wheel)
                .labelsHidden()
                .frame(maxWidth: .infinity)

            if let error = vm.errorMessage {
                Text(error).foregroundStyle(.red).font(.footnote)
            }

            Spacer()

            PrimaryButton(title: vm.primaryTitle, isLoading: vm.isLoading, isEnabled: vm.isOldEnough) {
                Task { await vm.next() }
            }
        }
        .padding(24)
    }
}

// TrainWithView.swift

struct TrainWithView: View {
    @EnvironmentObject var vm: OnboardingViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Who do you want to train with?")
                .font(.largeTitle.bold())
            Text("You can change this anytime in settings.")
                .foregroundStyle(.secondary)

            ForEach(TrainWithPreference.allCases, id: \.self) { option in
                SelectableRow(title: option.title, isSelected: vm.trainWith == option)
                    .onTapGesture { vm.trainWith = option }
            }

            if let error = vm.errorMessage {
                Text(error).foregroundStyle(.red).font(.footnote)
            }

            Spacer()

            PrimaryButton(title: vm.primaryTitle, isLoading: vm.isLoading, isEnabled: vm.trainWith != nil) {
                Task { await vm.next() }
            }
        }
        .padding(24)
    }
}

// ScheduleView.swift
struct ScheduleView: View {
    @EnvironmentObject var vm: OnboardingViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("When do you train?")
                .font(.largeTitle.bold())
            Text("Tap every time you usually lift. We'll match you with people who overlap.")
                .foregroundStyle(.secondary)

            Grid(horizontalSpacing: 8, verticalSpacing: 8) {
                GridRow {
                    Color.clear.frame(width: 44, height: 1)
                    ForEach(TimeWindow.allCases, id: \.self) { window in
                        VStack(spacing: 2) {
                            Text(window.title).font(.footnote.bold())
                            Text(window.hours).font(.caption2).foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                ForEach(Day.allCases, id: \.self) { day in
                    GridRow {
                        Text(day.title)
                            .font(.subheadline.bold())
                            .frame(width: 44, alignment: .leading)
                        ForEach(TimeWindow.allCases, id: \.self) { window in
                            let key = TrainingSlot.key(day, window)
                            let isOn = vm.availability.contains(key)
                            RoundedRectangle(cornerRadius: 10)
                                .fill(isOn ? Color.primary : Color.primary.opacity(0.06))
                                .frame(height: 44)
                                .overlay {
                                    if isOn {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(Color(.systemBackground))
                                    }
                                }
                                .onTapGesture { vm.toggleSlot(key) }
                        }
                    }
                }
            }

            if let error = vm.errorMessage {
                Text(error).foregroundStyle(.red).font(.footnote)
            }

            Spacer()

            PrimaryButton(title: vm.primaryTitle, isLoading: vm.isLoading, isEnabled: !vm.availability.isEmpty) {
                Task { await vm.next() }
            }
        }
        .padding(24)
    }
}

// Gender View.swift
struct GenderView: View {
    @EnvironmentObject var vm: OnboardingViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Which best describes you?")
                .font(.largeTitle.bold())
            Text("We use this so people can choose who they train with.")
                .foregroundStyle(.secondary)

            ForEach(Gender.allCases, id: \.self) { option in
                SelectableRow(title: option.title, isSelected: vm.gender == option)
                    .onTapGesture { vm.gender = option }
            }

            if let error = vm.errorMessage {
                Text(error).foregroundStyle(.red).font(.footnote)
            }

            Spacer()

            PrimaryButton(title: vm.primaryTitle, isLoading: vm.isLoading, isEnabled: vm.gender != nil) {
                Task { await vm.next() }
            }
        }
        .padding(24)
    }
}

// TrainingStyleView.swift
struct TrainingStyleView: View {
    @EnvironmentObject var vm: OnboardingViewModel

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("How do you train?")
                .font(.largeTitle.bold())
            Text("Pick up to 3 · \(vm.trainingStyles.count) of 3 selected")
                .foregroundStyle(.secondary)

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(TrainingStyle.allCases, id: \.self) { style in
                    let isOn = vm.trainingStyles.contains(style)
                    Text(style.title)
                        .font(.subheadline.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(isOn ? Color.primary : Color.primary.opacity(0.06),
                                    in: RoundedRectangle(cornerRadius: 12))
                        .foregroundStyle(isOn ? Color(.systemBackground) : Color.primary)
                        .contentShape(Rectangle())
                        .onTapGesture { vm.toggleStyle(style) }
                }
            }

            if let error = vm.errorMessage {
                Text(error).foregroundStyle(.red).font(.footnote)
            }

            Spacer()

            PrimaryButton(title: vm.primaryTitle,
                          isLoading: vm.isLoading,
                          isEnabled: !vm.trainingStyles.isEmpty) {
                Task { await vm.next() }
            }
        }
        .padding(24)
    }
}

// ExperienceView.swift
struct ExperienceView: View {
    @EnvironmentObject var vm: OnboardingViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("How long have you been lifting?")
                .font(.largeTitle.bold())
            Text("Helps match you with partners at a similar level.")
                .foregroundStyle(.secondary)

            ForEach(ExperienceLevel.allCases, id: \.self) { level in
                SelectableRow(title: level.title,
                              subtitle: level.subtitle,
                              isSelected: vm.experience == level)
                    .onTapGesture { vm.experience = level }
            }

            if let error = vm.errorMessage {
                Text(error).foregroundStyle(.red).font(.footnote)
            }

            Spacer()

            PrimaryButton(title: vm.primaryTitle, isLoading: vm.isLoading, isEnabled: vm.experience != nil) {
                Task { await vm.next() }
            }
        }
        .padding(24)
    }
}

// GoalView.swift
struct GoalView: View {
    @EnvironmentObject var vm: OnboardingViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("What's your main goal?")
                .font(.largeTitle.bold())
            Text("Pick the one that fits right now.")
                .foregroundStyle(.secondary)

            ForEach(FitnessGoal.allCases, id: \.self) { goal in
                SelectableRow(title: goal.title,
                              subtitle: goal.subtitle,
                              isSelected: vm.goal == goal)
                    .onTapGesture { vm.goal = goal }
            }

            if let error = vm.errorMessage {
                Text(error).foregroundStyle(.red).font(.footnote)
            }

            Spacer()

            PrimaryButton(title: vm.primaryTitle, isLoading: vm.isLoading, isEnabled: vm.goal != nil) {
                Task { await vm.next() }
            }
        }
        .padding(24)
    }
}

// LiftsView.swift
struct LiftsView: View {
    @EnvironmentObject var vm: OnboardingViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("What are your lifts?")
                .font(.largeTitle.bold())
            Text("Your best single, in pounds. Rough numbers are fine, and everything is optional.")
                .foregroundStyle(.secondary)

            ScrollView {
                VStack(spacing: 12) {
                    LiftField(title: "Bench press", text: $vm.benchText)
                    LiftField(title: "Squat", text: $vm.squatText)
                    LiftField(title: "Deadlift", text: $vm.deadliftText)
                    LiftField(title: "Overhead press", text: $vm.ohpText)
                }
            }
            .scrollDismissesKeyboard(.interactively)

            if let error = vm.errorMessage {
                Text(error).foregroundStyle(.red).font(.footnote)
            }

            PrimaryButton(title: vm.primaryTitle, isLoading: vm.isLoading) {
                Task { await vm.next() }
            }

            Button("Skip for now") {
                Task { await vm.skipLifts() }
            }
            .font(.subheadline.bold())
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity)
        }
        .padding(24)
    }
}

struct LiftField: View {
    let title: String
    @Binding var text: String

    var body: some View {
        HStack {
            Text(title).font(.headline)
            Spacer()
            TextField("0", text: $text)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .font(.title3)
                .frame(width: 90)
                .onChange(of: text) { _, new in
                    let cleaned = String(new.filter(\.isNumber).prefix(4))
                    if cleaned != new { text = cleaned }
                }
            Text("lb").foregroundStyle(.secondary)
        }
        .padding(16)
        .background(Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 12))
    }
}

//DoneView.swift
struct DoneView: View {
    @EnvironmentObject var vm: OnboardingViewModel

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
            Text("You're all set, \(vm.firstName)!")
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)
            Text("Time to find your gym bros.")
                .foregroundStyle(.secondary)
            Spacer()

            if let error = vm.errorMessage {
                Text(error).foregroundStyle(.red).font(.footnote)
            }

            PrimaryButton(title: "Start finding gym bros", isLoading: vm.isLoading) {
                Task { await vm.finish() }
            }
        }
        .padding(24)
    }
}

// Notificationspromptvieew.swift
struct NotificationsPromptView: View {
    @EnvironmentObject var vm: OnboardingViewModel

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "bell.badge.fill")
                .font(.system(size: 64))
            Text("Don't miss a match")
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)
            Text("Turn on notifications so you know when someone wants to lift with you or sends a message.")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Spacer()

            PrimaryButton(title: "Turn on notifications", isLoading: vm.isLoading) {
                Task {
                    await NotificationService.shared.requestPermission()
                    await vm.next()
                }
            }

            Button("Not now") {
                Task { await vm.next() }
            }
            .font(.subheadline.bold())
            .foregroundStyle(.secondary)
        }
        .padding(24)
    }
}
