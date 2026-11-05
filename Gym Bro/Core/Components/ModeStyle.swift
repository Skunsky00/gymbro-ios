//
//  ModeStyle.swift
//  Gym Bro
//
//  Created by Jacob Johnson on 11/2/26.
//

import SwiftUI

extension Color {
    /// Marks dating likes and matches.
    static let dateAccent = Color(red: 0.90, green: 0.22, blue: 0.32)
}

/// A small red heart showing something is a date, not a gym-partner match.
struct DateHeartBadge: View {
    var size: CGFloat = 20

    var body: some View {
        Image(systemName: "heart.fill")
            .font(.system(size: size * 0.5, weight: .bold))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(Color.dateAccent, in: Circle())
            .overlay(Circle().stroke(Color(.systemBackground), lineWidth: 2))
    }
}

struct ModeFilterPicker: View {
    @Binding var filter: ModeFilter

    var body: some View {
        Picker("Show", selection: $filter) {
            ForEach(ModeFilter.allCases) { Text($0.title).tag($0) }
        }
        .pickerStyle(.segmented)
    }
}
