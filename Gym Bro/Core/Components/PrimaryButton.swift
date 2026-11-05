//
//  PrimaryButton.swift
//  Gym Bro
//
//  Created by Jacob Johnson on 10/23/26.
//

import SwiftUI

struct PrimaryButton: View {
    let title: String
    var isLoading = false
    var isEnabled = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Group {
                if isLoading {
                    ProgressView().tint(Color(.systemBackground))
                } else {
                    Text(title).bold()
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.primary, in: Capsule())
            .foregroundStyle(Color(.systemBackground))
        }
        .disabled(!isEnabled || isLoading)
        .opacity(isEnabled ? 1 : 0.4)
    }
}
