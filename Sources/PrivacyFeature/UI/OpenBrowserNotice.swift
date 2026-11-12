import SwiftUI

/// Warns that a browser is open, so its caches are locked, and offers to quit it.
struct OpenBrowserNotice: View {
    let browserName: String
    let isQuitting: Bool
    let onQuit: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.yellow)
                .accessibilityHidden(true)

            Text(
                "Quit \(browserName) to clear its caches.",
                bundle: .module,
                comment: "Notice shown on an open browser, whose caches can't be cleared. The argument is its name."
            )
            .frame(maxWidth: .infinity, alignment: .leading)

            if isQuitting {
                ProgressView()
                    .controlSize(.small)
            } else {
                Button(action: onQuit) {
                    Text("Quit \(browserName)", bundle: .module, comment: "Button that asks an open browser to quit. The argument is its name.")
                }
            }
        }
        .padding(12)
        .background(Color.yellow.opacity(0.10), in: .rect(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.yellow.opacity(0.3), lineWidth: 1))
    }
}
