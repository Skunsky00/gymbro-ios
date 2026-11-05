//
//  ProfileViewModel.swift
//  Gym Bro
//
//  Created by Jacob Johnson on 10/24/26.
//

import SwiftUI
import Combine

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published var user: AppUser?
    @Published var isLoading = true

    func load(userID: String) async {
        user = try? await UserService.shared.fetchUser(id: userID)
        isLoading = false
    }
}
