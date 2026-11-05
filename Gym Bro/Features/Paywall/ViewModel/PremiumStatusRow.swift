//
//  PremiumStatusRow.swift
//  Gym Bro
//
//  Created by Jacob Johnson on 11/1/26.
//

import Foundation
import SwiftUI

struct PremiumStatusRow: View {
    @ObservedObject private var purchases = PurchaseService.shared
    @State private var showPaywall = false

    var body: some View {
        if purchases.isPremium {
            VStack(alignment: .leading, spacing: 6) {
                Label(Brand.premiumName, systemImage: "checkmark.seal.fill").font(.headline)
                Link("Manage subscription", destination: AppLinks.manageSubscriptions)
                    .font(.subheadline)
            }
        } else {
            Button { showPaywall = true } label: {
                Label("Upgrade to \(Brand.premiumName)", systemImage: "heart.text.square.fill")
                    .font(.headline)
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView(reason: .general)
                    .presentationDetents([.medium, .large])
            }
        }
    }
}
