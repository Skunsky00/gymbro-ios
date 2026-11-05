//
//  PhoneEntryView.swift
//  Gym Bro
//
//  Created by Jacob Johnson on 10/23/26.
//

import SwiftUI

struct PhoneEntryView: View {
    @EnvironmentObject var viewModel: AuthViewModel
    @FocusState private var isFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 24) {
                Text("What's your number?")
                    .font(.largeTitle.bold())
                Text("We'll text you a code to verify it's you.")
                    .foregroundStyle(.secondary)

                VStack(spacing: 8) {
                    HStack(spacing: 12) {
                        Text("🇺🇸 +1")
                        Divider().frame(height: 24)
                        TextField("(555) 555-5555", text: $viewModel.phoneNumber)
                            .keyboardType(.numberPad)
                            .textContentType(.telephoneNumber)
                            .focused($isFocused)
                            .onChange(of: viewModel.phoneNumber) { _, new in
                                let formatted = new.formattedUSPhone
                                if formatted != new { viewModel.phoneNumber = formatted }
                            }
                    }
                    .font(.title3)
                    Divider()
                }

                if let error = viewModel.errorMessage {
                    Text(error).foregroundStyle(.red).font(.footnote)
                }

                Spacer()

                PrimaryButton(
                    title: "Next",
                    isLoading: viewModel.isLoading,
                    isEnabled: viewModel.phoneNumber.isValidUSPhone
                ) {
                    Task { await viewModel.sendCode() }
                }
            }
            .padding(24)
            .onAppear { isFocused = true }
            .navigationDestination(isPresented: $viewModel.codeSent) {
                CodeVerificationView()
            }
        }
    }
}
