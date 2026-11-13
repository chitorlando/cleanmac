import SwiftUI

/// What to do in System Settings, next to a picture of the switch to turn on.
struct FullDiskAccessHint: View {
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "switch.2")
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
            Text(
                "In the list, turn on CleanMac. If it isn’t there, add it with the + button.",
                bundle: .module,
                comment: "Hint on how to grant Full Disk Access in System Settings."
            )
            .font(.caption)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
        }
    }
}
