//
//  PhotoLikeSheet.swift
//  Gym Bro
//
//  Created by Jacob Johnson on 10/30/26.
//

import SwiftUI

struct PhotoLikeTarget: Identifiable {
    let url: String
    var id: String { url }
}

struct PhotoLikeSheet: View {
    let name: String
    let photoURL: String
    let onSend: (String?) -> Void

    @State private var comment = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 16) {
            AsyncImage(url: URL(string: photoURL)) { phase in
                if let image = phase.image {
                    image.resizable().scaledToFill()
                } else {
                    Color.primary.opacity(0.08)
                }
            }
            .frame(height: 300)
            .frame(maxWidth: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: 16))

            TextField("Say something about it (optional)", text: $comment, axis: .vertical)
                .lineLimit(1...4)
                .padding(12)
                .background(Color.primary.opacity(0.06), in: RoundedRectangle(cornerRadius: 14))
                .onChange(of: comment) { _, new in
                    if new.count > 200 { comment = String(new.prefix(200)) }
                }

            PrimaryButton(title: "Send like to \(name)", isLoading: false, isEnabled: true) {
                let text = comment.trimmingCharacters(in: .whitespacesAndNewlines)
                onSend(text.isEmpty ? nil : text)
                dismiss()
            }
        }
        .padding(24)
    }
}
