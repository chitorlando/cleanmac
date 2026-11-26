import SwiftUI

/// Warns that a browser or another edition of it is open, so its caches are locked, and
/// offers to quit them.
struct OpenBrowserNotice: View {
    /// The open apps that lock the caches, such as "Firefox" and "Firefox Nightly".
    let appNames: [String]
    let isQuitting: Bool
    let onQuit: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.yellow)
                .accessibilityHidden(true)

            Text(
                "Quit \(names) to clear these caches.",
                bundle: .module,
                comment: "Notice on a browser whose caches are locked while it or another edition of it is open. The argument is the open apps."
            )
            .frame(maxWidth: .infinity, alignment: .leading)

            if isQuitting {
                ProgressView()
                    .controlSize(.small)
            } else {
                Button(action: onQuit) {
                    Text("Quit \(names)", bundle: .module, comment: "Button that asks the open apps that lock a browser's caches to quit.")
                }
            }
        }
        .padding(12)
        .background(Color.yellow.opacity(0.10), in: .rect(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.yellow.opacity(0.3), lineWidth: 1))
    }

    /// The names as a list in the user's language, such as "Firefox and Firefox Nightly".
    private var names: String {
        appNames.formatted(.list(type: .and))
    }
}
