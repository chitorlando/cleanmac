import CleanMacUI
import SwiftUI

/// Welcome state with the button that lists the installed apps.
struct UninstallerIntroView: View {
    let theme: FeatureTheme
    let onStart: () -> Void

    var body: some View {
        VStack(spacing: 48) {
            HeroHeader(
                symbolName: "app.badge.checkmark",
                title: String(localized: "Uninstaller", bundle: .module, comment: "Feature name in the sidebar."),
                subtitle: String(
                    localized: "Remove apps completely, together with the preferences, caches and support files they leave behind.",
                    bundle: .module,
                    comment: "Introduction of the uninstaller feature."
                ),
                theme: theme
            )
            Button(action: onStart) {
                Text("View Applications", bundle: .module, comment: "Button that lists the installed apps.")
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
            }
            .buttonStyle(GlowButtonStyle(theme: theme, shape: .circle(diameter: 148)))
            .keyboardShortcut(.defaultAction)
        }
    }
}
