//
//  SafteyMenu.swift
//  Gym Bro
//
//  Created by Jacob Johnson on 10/24/26.
//

import SwiftUI

struct SafetyMenu: View {
    let name: String
    var onPhoto = false
    var onUnmatch: (() async -> Void)? = nil
    let onBlock: () async -> Void
    let onReport: (ReportReason, String, Bool) async -> Void

    private enum Confirm { case block, unmatch }

    @State private var showReport = false
    @State private var confirm: Confirm?

    var body: some View {
        Menu {
            Button { showReport = true } label: {
                Label("Report \(name)", systemImage: "exclamationmark.bubble")
            }
            if onUnmatch != nil {
                Button { confirm = .unmatch } label: {
                    Label("Unmatch", systemImage: "person.fill.xmark")
                }
            }
            Button(role: .destructive) { confirm = .block } label: {
                Label("Block \(name)", systemImage: "hand.raised")
            }
        } label: {
            if onPhoto {
                Image(systemName: "ellipsis")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(.black.opacity(0.45), in: Circle())
            } else {
                Image(systemName: "ellipsis.circle")
                    .font(.title3)
                    .foregroundStyle(Color.primary)
            }
        }
        .sheet(isPresented: $showReport) {
            ReportView(name: name, onSubmit: onReport)
        }
        .confirmationDialog(
            confirm == .unmatch ? "Unmatch with \(name)?" : "Block \(name)?",
            isPresented: Binding(get: { confirm != nil },
                                 set: { if !$0 { confirm = nil } }),
            titleVisibility: .visible
        ) {
            if confirm == .unmatch {
                Button("Unmatch", role: .destructive) {
                    Task { await onUnmatch?() }
                }
            }
            if confirm == .block {
                Button("Block", role: .destructive) {
                    Task { await onBlock() }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You won't see each other again, and any chat will end.")
        }
    }
}
