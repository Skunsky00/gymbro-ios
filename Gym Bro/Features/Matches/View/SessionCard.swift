//
//  SessionCard.swift
//  Gym Bro
//
//  Created by Jacob Johnson on 10/23/26.
//

import SwiftUI

struct SessionCard: View {
    let session: SessionProposal
    let isMine: Bool
    let otherName: String
    let gymName: String?
    let onRespond: (Bool) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Training session", systemImage: "calendar")
                .font(.footnote.bold())
                .foregroundStyle(.secondary)
            Text(session.focus).font(.title3.bold())
            Text(session.startTime.formatted(.dateTime.weekday(.wide).month().day().hour().minute()))
                .font(.subheadline)
            if let gymName = session.gymName {
                Label(gymName, systemImage: "mappin.and.ellipse")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            status
        }
        .padding(16)
        .frame(maxWidth: 280, alignment: .leading)
        .background(Color.primary.opacity(0.06), in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.primary.opacity(0.15)))
    }

    @ViewBuilder
    private var status: some View {
        switch session.status {
        case .pending:
            if isMine {
                Text("Waiting for \(otherName)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else {
                HStack(spacing: 8) {
                    Button { onRespond(false) } label: {
                        Text("Decline")
                            .font(.subheadline.bold())
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.primary.opacity(0.1), in: Capsule())
                            .foregroundStyle(Color.primary)
                    }
                    Button { onRespond(true) } label: {
                        Text("Accept")
                            .font(.subheadline.bold())
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.primary, in: Capsule())
                            .foregroundStyle(Color(.systemBackground))
                    }
                }
            }
        case .accepted:
            Label("Confirmed", systemImage: "checkmark.circle.fill")
                .font(.footnote.bold())
        case .declined:
            Text("Declined")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }
}
