import CleanMacUI
import SwiftUI

/// Says that macOS keeps CleanMac out of a junk category, with a way to give it Full Disk Access.
struct JunkFullDiskAccessNote: View {
    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Label {
                Text(
                    "macOS keeps CleanMac out of it until you give CleanMac Full Disk Access.",
                    bundle: .module,
                    comment: "Note on a junk category that macOS keeps CleanMac from reading, next to the button that opens the Full Disk Access settings."
                )
            } icon: {
                Image(systemName: "lock.shield")
            }
            .font(.callout)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)

            FullDiskAccessSettingsButton()
        }
    }
}
