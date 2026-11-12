import CleanMacUI
import SwiftUI

/// A colored dot, a name and a size, matching a part of a bar.
struct BytesLegendRow: View {
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
            Text(Int64(clamping: bytes).formattedByteCount)
                .monospacedDigit()
        }
        .lineLimit(1)
        .accessibilityElement(children: .combine)
    }
}
