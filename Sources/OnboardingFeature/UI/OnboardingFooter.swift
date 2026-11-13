import CleanMacUI
import SwiftUI

/// "Skip for now" and "Continue", both always available: every permission is optional.
struct OnboardingFooter: View {
    let theme: FeatureTheme
    let onFinish: () -> Void

    var body: some View {
        HStack {
            Button(action: onFinish) {
                Text("Skip for now", bundle: .module, comment: "Button that leaves the permissions screen without granting them.")
            }
            .buttonStyle(.borderless)
            .foregroundStyle(.secondary)
            Spacer()
            Button(action: onFinish) {
                Text("Continue", bundle: .module, comment: "Button that leaves the permissions screen.")
            }
            .buttonStyle(GlowButtonStyle(theme: theme, shape: .capsule))
            .keyboardShortcut(.defaultAction)
        }
    }
}
