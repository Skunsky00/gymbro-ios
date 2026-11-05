//
//  DiscoverContainerView.swift
//  Gym Bro
//
//  Created by Jacob Johnson on 11/2/26.
//

import SwiftUI

struct DiscoverContainerView: View {
    @State private var page: MatchMode? = .train

    var body: some View {
        if FeatureFlags.dating {
            VStack(spacing: 0) {
                Picker("Mode", selection: modeBinding) {
                    ForEach(MatchMode.allCases, id: \.self) { Text($0.title).tag($0) }
                }
                .pickerStyle(.segmented)
                .frame(width: 220)
                .padding(.vertical, 8)

                GeometryReader { geo in
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 0) {
                            DiscoverView(mode: .train, isActive: page != .date)
                                .frame(width: geo.size.width, height: geo.size.height)
                                .id(MatchMode.train)
                            DiscoverView(mode: .date, isActive: page == .date)
                                .frame(width: geo.size.width, height: geo.size.height)
                                .id(MatchMode.date)
                        }
                        .scrollTargetLayout()
                    }
                    .scrollTargetBehavior(.paging)
                    .scrollPosition(id: $page)
                }
            }
        } else {
            DiscoverView(mode: .train, isActive: true)
        }
    }

    private var modeBinding: Binding<MatchMode> {
        Binding(
            get: { page ?? .train },
            set: { newValue in withAnimation { page = newValue } }
        )
    }
}
