//
//  ProposeSessionView.swift
//  Gym Bro
//
//  Created by Jacob Johnson on 10/23/26.
//

import SwiftUI

struct ProposeSessionView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var startTime = Date().addingTimeInterval(24 * 60 * 60)
    @State private var focus: String?
    @State private var useTheirGym = false

    let myGym: Gym?
    let theirGym: Gym?
    let theirName: String
    let onSend: (Date, String, String?) -> Void

    private let options = ["Chest", "Back", "Legs", "Shoulders", "Arms", "Push", "Pull", "Full body"]
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 3)

    private var chosenGym: Gym? {
        if let myGym, let theirGym {
            return myGym.id == theirGym.id ? myGym : (useTheirGym ? theirGym : myGym)
        }
        return myGym ?? theirGym
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("When do you want to train?")
                            .font(.title2.bold())
                        DatePicker("", selection: $startTime, in: Date()...,
                                   displayedComponents: [.date, .hourAndMinute])
                            .datePickerStyle(.compact)
                            .labelsHidden()

                        Text("What are you hitting?")
                            .font(.title2.bold())
                            .padding(.top, 8)
                        LazyVGrid(columns: columns, spacing: 10) {
                            ForEach(options, id: \.self) { option in
                                let isOn = focus == option
                                Text(option)
                                    .font(.subheadline.bold())
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(isOn ? Color.primary : Color.primary.opacity(0.06),
                                                in: RoundedRectangle(cornerRadius: 12))
                                    .foregroundStyle(isOn ? Color(.systemBackground) : Color.primary)
                                    .contentShape(Rectangle())
                                    .onTapGesture { focus = option }
                            }
                        }

                        if let myGym, let theirGym {
                            Text("Where?")
                                .font(.title2.bold())
                                .padding(.top, 8)
                            if myGym.id == theirGym.id {
                                Label(myGym.name, systemImage: "mappin.and.ellipse")
                                    .foregroundStyle(.secondary)
                            } else {
                                Picker("Where", selection: $useTheirGym) {
                                    Text("My gym").tag(false)
                                    Text("\(theirName)'s gym").tag(true)
                                }
                                .pickerStyle(.segmented)
                                Label(useTheirGym ? theirGym.name : myGym.name,
                                      systemImage: "mappin.and.ellipse")
                                    .foregroundStyle(.secondary)
                                Text("You train at different gyms, so one of you may need a guest or day pass.")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                PrimaryButton(title: "Send proposal", isEnabled: focus != nil) {
                    if let focus {
                        onSend(startTime, focus, chosenGym?.name)
                        dismiss()
                    }
                }
                .padding(.top, 12)
            }
            .padding(24)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color.primary)
                }
            }
        }
    }
}
