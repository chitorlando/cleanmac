import CleanMacUI
import SwiftUI

/// Welcome state with the main scan button.
struct JunkIdleView: View {
    let theme: FeatureTheme
    let onScan: () -> Void

    var body: some View {
        VStack(spacing: 48) {
            HeroHeader(
                symbolName: "trash.fill",
                title: String(localized: "System Junk", bundle: .module, comment: "Feature name in the sidebar."),
                subtitle: String(
                    localized: "Free up space by removing caches, logs and development leftovers you no longer need.",
                    bundle: .module,
                    comment: "Introduction of the system junk feature."
                ),
                theme: theme
            )
            Button(action: onScan) {
                Text("Scan", bundle: .module, comment: "Button that starts looking for junk.")
            }
            .buttonStyle(GlowButtonStyle(theme: theme, shape: .circle(diameter: 132)))
            .keyboardShortcut(.defaultAction)
        }
    }
}
