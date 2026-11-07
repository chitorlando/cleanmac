import CleanMacUI
import SwiftUI

/// Warns that the focused app is open and offers to quit it.
struct RunningAppNotice: View {
    let isQuitting: Bool
    let onQuit: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.yellow)
                .accessibilityHidden(true)

            Text(
                "This app is open. Quit it to uninstall it.",
                bundle: .module,
                comment: "Notice shown on the details of a running app."
            )
            .frame(maxWidth: .infinity, alignment: .leading)

            if isQuitting {
                ProgressView()
                    .controlSize(.small)
            } else {
                Button(action: onQuit) {
                    Text("Quit App", bundle: .module, comment: "Button that asks a running app to quit.")
                }
            }
        }
        .padding(12)
        .background(Color.yellow.opacity(0.10), in: .rect(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.yellow.opacity(0.3), lineWidth: 1))
    }
}
