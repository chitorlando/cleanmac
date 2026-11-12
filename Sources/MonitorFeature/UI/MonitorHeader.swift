import SwiftUI

/// Title of the screen with what it shows.
struct MonitorHeader: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Monitor", bundle: .module, comment: "Feature name in the sidebar.")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .accessibilityAddTraits(.isHeader)
            Text(
                "Processor, memory and disks of this Mac, updated every few seconds.",
                bundle: .module,
                comment: "Subtitle of the monitor screen."
            )
            .foregroundStyle(.secondary)
            .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
