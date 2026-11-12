import SwiftUI

/// A colored dot, a name and a percentage, matching a part of a chart.
struct LegendRow: View {
    let color: Color
    let title: Text
    let value: Double?

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 7, height: 7)
                .accessibilityHidden(true)
            title
                .foregroundStyle(.secondary)
            PercentText(value: value)
        }
        .lineLimit(1)
        .accessibilityElement(children: .combine)
    }
}
