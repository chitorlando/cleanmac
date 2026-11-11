import CleanMacUI
import SwiftUI

/// Welcome state with the button that lists the login items.
struct LoginItemsIntroView: View {
    let theme: FeatureTheme
    let onStart: () -> Void

    var body: some View {
        VStack(spacing: 48) {
            HeroHeader(
                symbolName: "power",
                title: String(localized: "Login Items", bundle: .module, comment: "Feature name in the sidebar."),
                subtitle: String(
                    localized: "See what starts when you log in or runs in the background, and remove what deleted apps left behind.",
                    bundle: .module,
                    comment: "Introduction of the login items feature."
                ),
                theme: theme
            )
            Button(action: onStart) {
                Text("View Login Items", bundle: .module, comment: "Button that lists the login items.")
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
            }
            .buttonStyle(GlowButtonStyle(theme: theme, shape: .circle(diameter: 148)))
            .keyboardShortcut(.defaultAction)
        }
    }
}
