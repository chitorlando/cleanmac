import CleanMacUI
import SwiftUI

/// A process with its app's icon and name, and what it uses in the chosen order.
struct ProcessRow: View {
    let process: ProcessUsage
    let ranking: ProcessRanking

    var body: some View {
        HStack(spacing: 8) {
            icon
            Text(verbatim: process.name)
                .lineLimit(1)
                .truncationMode(.middle)
            Spacer(minLength: 4)
            value
                .monospacedDigit()
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var icon: some View {
        if let iconURL = process.iconURL {
            AppIconView(url: iconURL, size: 18)
        } else {
            Image(systemName: "gearshape")
                .frame(width: 18, height: 18)
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
        }
    }

    @ViewBuilder
    private var value: some View {
        switch ranking {
        case .cpu:
            Text(process.cpu, format: .percent.precision(.fractionLength(0)))
        case .memory:
            Text(Int64(clamping: process.memoryBytes).formattedByteCount)
        }
    }
}
