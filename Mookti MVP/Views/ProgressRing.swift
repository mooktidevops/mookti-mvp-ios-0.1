//
//  ProgressRing.swift
//  Mookti
//

import SwiftUI

/// Circular progress indicator with an inner label.
struct ProgressRing: View {

    /// 0.0 … 1.0
    var percent: Double
    /// Text below the percentage (e.g. "CQ")
    var label: String

    var body: some View {
        ZStack {
            Circle()
                .stroke(.secondary.opacity(0.15), lineWidth: 14)

            Circle()
                .trim(from: 0, to: percent)
                .stroke(style: StrokeStyle(lineWidth: 14, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut, value: percent)

            VStack {
                Text(percent, format: .percent.precision(.fractionLength(0)))
                    .font(.title3).bold()
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 120, height: 120)
        .accessibilityElement()
        .accessibilityLabel(label)
        .accessibilityValue(Text(percent, format: .percent))
    }
}

#if DEBUG
struct ProgressRing_Previews: PreviewProvider {
    static var previews: some View {
        ProgressRing(percent: 0.73, label: "CQ")
    }
}
#endif
