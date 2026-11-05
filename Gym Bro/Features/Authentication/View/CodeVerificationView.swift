//
//  CodeVerificationView.swift
//  Gym Bro
//
//  Created by Jacob Johnson on 10/23/26.
//

import SwiftUI

struct CodeVerificationView: View {
    @EnvironmentObject var viewModel: AuthViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Enter your code")
                .font(.largeTitle.bold())
            Text("Sent to +1 \(viewModel.phoneNumber)")
                .foregroundStyle(.secondary)

            TextField("6-digit code", text: $viewModel.code)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .font(.title2.monospaced())
                .padding()
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 12))
                .onChange(of: viewModel.code) { _, newValue in
                    if newValue.count == 6 { Task { await viewModel.verifyCode() } }
                }

            if let error = viewModel.errorMessage {
                Text(error).foregroundStyle(.red).font(.footnote)
            }
            Spacer()
        }
        .padding()
    }
}
