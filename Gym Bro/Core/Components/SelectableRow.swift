//
//  SelectableRow.swift
//  Gym Bro
//
//  Created by Jacob Johnson on 10/23/26.
//

import SwiftUI

struct SelectableRow: View {
    let title: String
    var subtitle: String? = nil
    let isSelected: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline)
                if let subtitle {
                    Text(subtitle).font(.footnote).foregroundStyle(.secondary)
                }
            }
            Spacer()
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
        }
        .padding(16)
        .background(isSelected ? Color.primary.opacity(0.12) : Color.primary.opacity(0.04),
                    in: RoundedRectangle(cornerRadius: 12))
        .contentShape(Rectangle())
    }
}
