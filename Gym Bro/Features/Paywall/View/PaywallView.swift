//
//  PaywallView.swift
//  Gym Bro
//
//  Created by Jacob Johnson on 10/30/26.
//

import SwiftUI
import RevenueCat

struct PaywallView: View {
    let reason: PaywallReason
    @ObservedObject private var purchases = PurchaseService.shared
    @State private var selected: Package?
    @State private var finishedLoading = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                Image(systemName: reason == .unlimitedLikes ? "infinity" : "heart.text.square.fill")
                    .font(.system(size: 48))
                    .padding(.top, 8)

                Text(reason.title).font(.title.bold()).multilineTextAlignment(.center)
                Text(reason.subtitle).foregroundStyle(.secondary).multilineTextAlignment(.center)

                VStack(alignment: .leading, spacing: 12) {
                    Label("See everyone who likes you", systemImage: "heart.fill")
                    Label("Unlimited likes every day", systemImage: "infinity")
                    Label("Advanced filters and 50-mile distance", systemImage: "slider.horizontal.3")
                }
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(Color.primary.opacity(0.06), in: RoundedRectangle(cornerRadius: 16))

                plans

                if let message = purchases.message {
                    Text(message).font(.footnote).foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                PrimaryButton(title: "Subscribe",
                              isLoading: purchases.isBusy,
                              isEnabled: selected != nil && !purchases.isBusy) {
                    guard let selected else { return }
                    Task {
                        if await purchases.purchase(selected) == .activated { dismiss() }
                    }
                }

                Button("Restore Purchases") {
                    Task {
                        if await purchases.restore() == .activated { dismiss() }
                    }
                }
                .font(.subheadline)
                .disabled(purchases.isBusy)

                Text("Payment is charged to your Apple ID account at confirmation of purchase. "
                     + "Your subscription renews automatically unless you cancel at least 24 hours "
                     + "before the end of the current period. You can manage or cancel it in your "
                     + "App Store account settings.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                HStack(spacing: 20) {
                    Link("Terms of Use", destination: AppLinks.terms)
                    Link("Privacy Policy", destination: AppLinks.privacy)
                }
                .font(.caption)

                Button("Not now") { dismiss() }
                    .foregroundStyle(.secondary)
            }
            .padding(24)
        }
        .task {
            await purchases.loadOfferings()
            selected = selected ?? purchases.packages.first
            finishedLoading = true
        }
        .onChange(of: purchases.isPremium) { _, nowPremium in
            if nowPremium { dismiss() }
        }
    }

    @ViewBuilder
    private var plans: some View {
        if purchases.packages.isEmpty {
            if finishedLoading {
                Text("Plans aren't available right now. Try again later.")
                    .font(.footnote).foregroundStyle(.secondary)
            } else {
                ProgressView()
            }
        } else {
            VStack(spacing: 10) {
                ForEach(purchases.packages, id: \.identifier) { package in
                    Button { selected = package } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(package.storeProduct.localizedTitle).font(.headline)
                                Text(periodText(package))
                                    .font(.footnote).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(package.storeProduct.localizedPriceString).font(.headline)
                            Image(systemName: selected?.identifier == package.identifier
                                  ? "checkmark.circle.fill" : "circle")
                        }
                        .foregroundStyle(Color.primary)
                        .padding(14)
                        .background(Color.primary.opacity(0.06),
                                    in: RoundedRectangle(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(selected?.identifier == package.identifier
                                        ? Color.primary : Color.clear, lineWidth: 2)
                        )
                    }
                }
            }
        }
    }

    private func periodText(_ package: Package) -> String {
        switch package.packageType {
        case .weekly: return "per week"
        case .monthly: return "per month"
        case .twoMonth: return "every 2 months"
        case .threeMonth: return "every 3 months"
        case .sixMonth: return "every 6 months"
        case .annual: return "per year"
        case .lifetime: return "one-time purchase"
        default: return ""
        }
    }
}
