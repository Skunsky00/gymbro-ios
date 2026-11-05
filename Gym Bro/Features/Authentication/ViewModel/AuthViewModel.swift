//
//  AuthViewModel.swift
//  Gym Bro
//
//  Created by Jacob Johnson on 10/23/26.
//

import SwiftUI
import Combine
import FirebaseAuth

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var phoneNumber = ""
    @Published var code = ""
    @Published var codeSent = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var userSession: FirebaseAuth.User?

    private var verificationID: String?
    private let authService = AuthService.shared

    init() {
        userSession = Auth.auth().currentUser
    }


    func sendCode() async {
        print("sendCode tapped, number:", phoneNumber, "->", phoneNumber.e164US)
        guard phoneNumber.isValidUSPhone else {
            print("failed validation")
            errorMessage = "Enter a valid 10-digit number"
            return
        }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            verificationID = try await authService.sendCode(to: phoneNumber.e164US)
            print("code sent, verificationID:", verificationID ?? "nil")
            codeSent = true
        } catch {
            print("sendCode error:", error)
            errorMessage = error.localizedDescription
        }
    }

    func verifyCode() async {
        guard let verificationID, code.count == 6 else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            userSession = try await authService.verify(code: code, verificationID: verificationID)
        } catch {
            code = ""
            errorMessage = "That code didn't work. Try again."
        }
    }

    func signOut() {
        try? authService.signOut()
        Task { await PurchaseService.shared.reset() }
        userSession = nil
        phoneNumber = ""
        code = ""
        codeSent = false
        verificationID = nil
        errorMessage = nil
    }
}
