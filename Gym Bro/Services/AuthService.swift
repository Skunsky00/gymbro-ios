//
//  AuthService.swift
//  Gym Bro
//
//  Created by Jacob Johnson on 10/23/26.
//

import Foundation
import FirebaseAuth

final class AuthService {
    static let shared = AuthService()
    private init() {}

    func sendCode(to phoneNumber: String) async throws -> String {
        try await PhoneAuthProvider.provider()
            .verifyPhoneNumber(phoneNumber, uiDelegate: nil)
    }

    func verify(code: String, verificationID: String) async throws -> FirebaseAuth.User {
        let credential = PhoneAuthProvider.provider()
            .credential(withVerificationID: verificationID, verificationCode: code)
        let result = try await Auth.auth().signIn(with: credential)
        return result.user
    }

    func signOut() throws {
        try Auth.auth().signOut()
    }
}
