//
//  RangeSlider.swift
//  Gym Bro
//
//  Created by Jacob Johnson on 10/24/26.
//

import SwiftUI

struct RangeSlider: View {
    @Binding var lower: Int
    @Binding var upper: Int
    let bounds: ClosedRange<Int>
    var minGap = 1

    private let thumbSize: CGFloat = 28

    var body: some View {
        GeometryReader { geo in
            let usable = max(geo.size.width - thumbSize, 1)
            let span = Double(bounds.upperBound - bounds.lowerBound)
            let lowX = CGFloat(Double(lower - bounds.lowerBound) / span) * usable
            let highX = CGFloat(Double(upper - bounds.lowerBound) / span) * usable

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.primary.opacity(0.15))
                    .frame(height: 4)
                    .padding(.horizontal, thumbSize / 2)
                Capsule()
                    .fill(Color.primary)
                    .frame(width: max(highX - lowX, 0), height: 4)
                    .offset(x: lowX + thumbSize / 2)
                thumb
                    .offset(x: lowX)
                    .gesture(drag(usable: usable, span: span, isLower: true))
                thumb
                    .offset(x: highX)
                    .gesture(drag(usable: usable, span: span, isLower: false))
            }
            .coordinateSpace(.named("rangeSlider"))
            .frame(height: thumbSize)
        }
        .frame(height: thumbSize)
    }

    private var thumb: some View {
        Circle()
            .fill(Color(.systemBackground))
            .overlay(Circle().stroke(Color.primary, lineWidth: 2))
            .frame(width: thumbSize, height: thumbSize)
            .shadow(radius: 1)
    }

    private func drag(usable: CGFloat, span: Double, isLower: Bool) -> some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .named("rangeSlider"))
            .onChanged { value in
                let ratio = min(max(Double((value.location.x - thumbSize / 2) / usable), 0), 1)
                let newValue = bounds.lowerBound + Int((ratio * span).rounded())
                if isLower {
                    lower = min(max(newValue, bounds.lowerBound), upper - minGap)
                } else {
                    upper = max(min(newValue, bounds.upperBound), lower + minGap)
                }
            }
    }
}
