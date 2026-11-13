import SwiftUI

/// Quiet reminder, under the sidebar, that Full Disk Access is off. It opens the permissions screen.
public struct FullDiskAccessNotice: View {
    private let action: () -> Void

    public init(action: @escaping () -> Void) {
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Label {
                Text("Full Disk Access is off", bundle: .module, comment: "Reminder in the sidebar that opens the permissions screen.")
            } icon: {
                Image(systemName: "exclamationmark.shield.fill")
                    .foregroundStyle(.orange)
            }
            .font(.caption)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .foregroundStyle(.secondary)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .help(Text("Some folders can’t be analyzed. Click to set it up.", bundle: .module, comment: "Tooltip of the Full Disk Access reminder."))
    }
}
