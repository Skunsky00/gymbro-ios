//
//  MatchView.swift
//  Gym Bro
//
//  Created by Jacob Johnson on 10/23/26.
//

import SwiftUI

struct MatchView: View {
    let user: AppUser
    var mode: MatchMode = .train
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            if mode == .date {
                Image(systemName: "heart.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(Color.dateAccent)
            }
            Text("It's a match!")
                .font(.largeTitle.bold())
            Text(mode == .date
                 ? "You and \(user.firstName) liked each other. Say hi, or plan a gym date."
                 : "You and \(user.firstName) both want to train. Pick a time and hit a lift.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            if let url = user.photoURLs?.first {
                RemotePhoto(urlString: url)
                    .frame(width: 200)
            }
            Spacer()
            PrimaryButton(title: "Keep browsing") { dismiss() }
        }
        .padding(24)
    }
}
