//
//  ProfileCardView.swift
//  Gym Bro
//
//  Created by Jacob Johnson on 10/23/26.
//

import SwiftUI

struct ProfileCardView: View {
    let user: AppUser
    let overlap: [String]?
    var gymNote: String? = nil
    var onLikePhoto: ((String) -> Void)? = nil   // new

    private var chips: [String] {
        (user.trainingStyles ?? []).map(\.title)
            + [user.experience?.title, user.goal?.title].compactMap { $0 }
    }

    private var liftItems: [(String, Int)] {
        guard let lifts = user.lifts else { return [] }
        let all: [(String, Int?)] = [
            ("Bench", lifts.benchLb),
            ("Squat", lifts.squatLb),
            ("Deadlift", lifts.deadliftLb),
            ("OHP", lifts.overheadPressLb)
        ]
        return all.compactMap { name, value in value.map { (name, $0) } }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let first = user.photoURLs?.first {
                photoView(first)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("\(user.firstName)\(user.age.map { ", \($0)" } ?? "")")
                    .font(.largeTitle.bold())
                if let gym = user.homeGym {
                    Label(gym.name, systemImage: "mappin.and.ellipse")
                        .foregroundStyle(.secondary)
                    if let gymNote {
                        Text(gymNote)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            if let caption = user.caption, !caption.isEmpty {
                Text(caption)
                    .font(.title3)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(Color.primary.opacity(0.06), in: RoundedRectangle(cornerRadius: 16))
            }

            if !chips.isEmpty {
                FlowLayout(spacing: 8) {
                    ForEach(chips, id: \.self) { Chip(text: $0) }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            if let overlap {
                VStack(alignment: .leading, spacing: 4) {
                    Text(overlap.isEmpty ? "Your schedules don't overlap yet" : "You both train")
                        .font(.footnote.bold())
                        .foregroundStyle(.secondary)
                    if !overlap.isEmpty {
                        Text(overlap.joined(separator: ", "))
                            .font(.headline)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(Color.primary.opacity(0.06), in: RoundedRectangle(cornerRadius: 16))
            }

            if !liftItems.isEmpty {
                HStack(spacing: 8) {
                    ForEach(liftItems, id: \.0) { name, weight in
                        VStack(spacing: 2) {
                            Text("\(weight)").font(.title3.bold())
                            Text(name).font(.caption).foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.primary.opacity(0.06),
                                    in: RoundedRectangle(cornerRadius: 12))
                    }
                }
            }

            ForEach(Array((user.photoURLs ?? []).dropFirst().enumerated()), id: \.offset) { _, url in
                photoView(url)
            }
        }
    }
    @ViewBuilder
        private func photoView(_ url: String) -> some View {
            RemotePhoto(urlString: url)
                .overlay(alignment: .bottomTrailing) {
                    if let onLikePhoto {
                        Button { onLikePhoto(url) } label: {
                            Image(systemName: "heart.fill")
                                .font(.title3)
                                .foregroundStyle(Color(.systemBackground))
                                .frame(width: 44, height: 44)
                                .background(Color.primary, in: Circle())
                        }
                        .padding(12)
                    }
                }
        }
}

struct Chip: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.footnote.bold())
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.primary.opacity(0.08), in: Capsule())
    }
}

