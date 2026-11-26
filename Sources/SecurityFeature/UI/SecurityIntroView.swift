import CleanMacUI
import SwiftUI

/// Welcome state with the main button, which says plainly what the review is and isn't.
struct SecurityIntroView: View {
    let theme: FeatureTheme
    let onReview: () -> Void

    var body: some View {
        VStack(spacing: 48) {
            HeroHeader(
                symbolName: "checkmark.shield.fill",
                title: String(localized: "Security", bundle: .module, comment: "Feature name in the sidebar."),
                subtitle: String(
                    localized: "See how well your Mac is protected, in plain words and with the next step for anything worth a look. It isn’t an antivirus: it doesn’t look for malware. It only reads, changes nothing and sends nothing anywhere.",
                    bundle: .module,
                    comment: "Introduction of the security review."
                ),
                theme: theme
            )
            Button(action: onReview) {
                Text("Review", bundle: .module, comment: "Button that starts the security review.")
            }
            .buttonStyle(GlowButtonStyle(theme: theme, shape: .circle(diameter: 132)))
            .keyboardShortcut(.defaultAction)
        }
    }
}
