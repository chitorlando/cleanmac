import SwiftUI

/// A colored dot, a name and an amount of memory, matching a part of the memory bar.
struct MemoryLegendRow: View {
    let color: Color
    let title: Text
    let bytes: UInt64

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 7, height: 7)
                .accessibilityHidden(true)
            title
                .foregroundStyle(.secondary)
            Text(bytes.formattedMemorySize)
                .monospacedDigit()
        }
        .lineLimit(1)
        .accessibilityElement(children: .combine)
    }
}
