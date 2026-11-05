//
//  PurchaseService.swift
//  Gym Bro
//
//  Created by Jacob Johnson on 11/1/26.
//

import SwiftUI
import RevenueCat
import Combine

@MainActor
final class PurchaseService: ObservableObject {
    static let shared = PurchaseService()

    // Public SDK key from the RevenueCat dashboard. It's safe to ship in the app.
    private nonisolated static let apiKey = "appl_HcnWeJFXpzrzezTIkruJdEDRyIQ"
    private static let entitlementID = "premium"

    enum Outcome { case activated, pending, cancelled, failed }

    @Published private(set) var isPremium = false
    @Published private(set) var packages: [Package] = []
    @Published private(set) var isBusy = false
    @Published var message: String?

    private var identifiedUID: String?
    private init() {}

    /// Call once at launch, right after FirebaseApp.configure().
    nonisolated static func configure() {
        Purchases.logLevel = .debug          // lower this before release
        Purchases.configure(withAPIKey: apiKey)
    }

    /// Links purchases to the Firebase user. The webhook relies on this ID.
    func identify(uid: String) async {
        guard identifiedUID != uid else { return }
        do {
            _ = try await Purchases.shared.logIn(uid)
            identifiedUID = uid
            await refreshFromServer()
        } catch {
            print("revenuecat login error:", error)
        }
    }

    func reset() async {
        identifiedUID = nil
        isPremium = false
        packages = []
        _ = try? await Purchases.shared.logOut()
    }

    /// The server is the source of truth for who is premium.
    func refreshFromServer() async {
        do {
            isPremium = try await EntitlementService.shared.fetchLikeStatus().isPremium
        } catch {
            print("entitlement refresh error:", error)
        }
    }

    func loadOfferings() async {
        do {
            packages = try await Purchases.shared.offerings().current?.availablePackages ?? []
        } catch {
            print("offerings error:", error)
        }
    }

    func purchase(_ package: Package) async -> Outcome {
        guard identifiedUID != nil else {
            message = "Please sign out and back in, then try again."
            return .failed
        }
        isBusy = true
        message = nil
        defer { isBusy = false }
        do {
            let result = try await Purchases.shared.purchase(package: package)
            if result.userCancelled { return .cancelled }
            return await waitForServer()
        } catch {
            print("purchase error:", error)
            message = "The purchase didn't go through."
            return .failed
        }
    }

    func restore() async -> Outcome {
        guard identifiedUID != nil else {
            message = "Please sign out and back in, then try again."
            return .failed
        }
        isBusy = true
        message = nil
        defer { isBusy = false }
        do {
            let info = try await Purchases.shared.restorePurchases()
            guard info.entitlements[Self.entitlementID]?.isActive == true else {
                message = "No active subscription found to restore."
                return .failed
            }
            return await waitForServer()
        } catch {
            print("restore error:", error)
            message = "Couldn't restore purchases."
            return .failed
        }
    }

    /// The webhook can take a few seconds, so ask the server until it agrees.
    private func waitForServer() async -> Outcome {
        for _ in 0..<10 {
            await refreshFromServer()
            if isPremium { return .activated }
            try? await Task.sleep(nanoseconds: 2_000_000_000)
        }
        message = "Your purchase went through and is still activating. This can take a minute."
        return .pending
    }
}
