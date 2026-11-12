import CleanMacUI
import SwiftUI

/// Welcome state with the main scan button.
struct PrivacyIntroView: View {
    let theme: FeatureTheme
    let onScan: () -> Void

    var body: some View {
        VStack(spacing: 48) {
            HeroHeader(
                symbolName: "hand.raised.fill",
                title: String(localized: "Privacy", bundle: .module, comment: "Feature name in the sidebar."),
                subtitle: String(
                    localized: "Clear the caches your browsers keep of the pages you visit. History, passwords and cookies stay untouched.",
                    bundle: .module,
                    comment: "Introduction of the privacy feature."
                ),
                theme: theme
            )
            Button(action: onScan) {
                Text("Scan", bundle: .module, comment: "Button that starts looking for browser caches.")
            }
            .buttonStyle(GlowButtonStyle(theme: theme, shape: .circle(diameter: 132)))
            .keyboardShortcut(.defaultAction)
        }
    }
}
