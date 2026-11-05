//
//  CaptionEditView.swift
//  Gym Bro
//
//  Created by Jacob Johnson on 11/2/26.
//

import SwiftUI
import FirebaseFunctions

struct CaptionEditView: View {
    let uid: String
    let onSaved: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var text: String
    @State private var isSaving = false
    @State private var errorMessage: String?

    private let limit = 150

    init(uid: String, initial: String, onSaved: @escaping () -> Void) {
        self.uid = uid
        self.onSaved = onSaved
        _text = State(initialValue: initial)
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                Text("Add a short line that shows on your profile.")
                    .foregroundStyle(.secondary)
                TextField("Caption", text: $text, axis: .vertical)
                    .lineLimit(2...6)
                    .padding(12)
                    .background(Color.primary.opacity(0.06), in: RoundedRectangle(cornerRadius: 14))
                    .onChange(of: text) { _, new in
                        if new.count > limit { text = String(new.prefix(limit)) }
                    }
                HStack {
                    if let errorMessage { Text(errorMessage).foregroundStyle(.red) }
                    Spacer()
                    Text("\(text.count)/\(limit)").foregroundStyle(.secondary)
                }
                .font(.footnote)
                Spacer()
            }
            .padding(20)
            .navigationTitle("Caption")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(isSaving)
                }
            }
        }
    }

    /// Trims spaces and line breaks using plain Swift, and caps the length.
    private var cleaned: String {
        var s = Substring(text)
        while let first = s.first, first.isWhitespace || first.isNewline { s.removeFirst() }
        while let last = s.last, last.isWhitespace || last.isNewline { s.removeLast() }
        return String(s.prefix(limit))
    }

    private func save() {
        print("caption: save tapped")
        let clean = cleaned
        isSaving = true
        errorMessage = nil
        Task { @MainActor in
            do {
                print("caption: calling service")
                try await UserService.shared.updateCaption(uid: uid, caption: clean)
                print("caption: saved")
                isSaving = false
                onSaved()
                dismiss()
            } catch {
                isSaving = false
                let ns = error as NSError
                if ns.domain == FunctionsErrorDomain,
                   ns.code == FunctionsErrorCode.invalidArgument.rawValue {
                    // The server's message, e.g. "That caption doesn't meet our guidelines."
                    errorMessage = ns.localizedDescription
                } else {
                    errorMessage = "Couldn't save. Try again."
                }
                print("caption save error:", error)
            }
        }
    }
}
