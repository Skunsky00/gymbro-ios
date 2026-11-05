//
//  ReportView.swift
//  Gym Bro
//
//  Created by Jacob Johnson on 10/24/26.
//

import SwiftUI

struct ReportView: View {
    @Environment(\.dismiss) private var dismiss
    let name: String
    let onSubmit: (ReportReason, String, Bool) async -> Void

    @State private var reason: ReportReason?
    @State private var details = ""
    @State private var alsoBlock = true
    @State private var isSubmitting = false
    @State private var submitted = false

    var body: some View {
        NavigationStack {
            Group {
                if submitted { thanks } else { form }
            }
            .padding(24)
            .toolbar {
                if !submitted {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Cancel") { dismiss() }
                            .foregroundStyle(Color.primary)
                    }
                }
            }
        }
    }

    private var form: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Report \(name)")
                .font(.title.bold())
            Text("What's going on? Your report is private.")
                .foregroundStyle(.secondary)

            ScrollView {
                VStack(spacing: 10) {
                    ForEach(ReportReason.allCases) { option in
                        SelectableRow(title: option.title, isSelected: reason == option)
                            .onTapGesture { reason = option }
                    }

                    TextField("Add details (optional)", text: $details, axis: .vertical)
                        .lineLimit(2...5)
                        .padding(12)
                        .background(Color.primary.opacity(0.06),
                                    in: RoundedRectangle(cornerRadius: 12))

                    Toggle("Also block \(name)", isOn: $alsoBlock)
                        .padding(.top, 4)
                }
            }
            .scrollDismissesKeyboard(.interactively)

            PrimaryButton(title: "Submit report",
                          isLoading: isSubmitting,
                          isEnabled: reason != nil) {
                guard let reason else { return }
                isSubmitting = true
                Task {
                    await onSubmit(reason, details, alsoBlock)
                    isSubmitting = false
                    submitted = true
                }
            }
        }
    }

    private var thanks: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "checkmark.circle.fill").font(.system(size: 64))
            Text("Thanks for letting us know")
                .font(.title2.bold())
            Text("We'll review this report.")
                .foregroundStyle(.secondary)
            Spacer()
            PrimaryButton(title: "Done") { dismiss() }
        }
    }
}
