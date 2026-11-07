import CleanMacUI
import SwiftUI

/// Welcome state with the main scan button.
struct LargeFilesIntroView: View {
    let theme: FeatureTheme
    let onScan: () -> Void

    var body: some View {
        VStack(spacing: 48) {
            HeroHeader(
                symbolName: "doc.richtext",
                title: String(localized: "Large Files", bundle: .module, comment: "Feature name in the sidebar."),
                subtitle: String(
                    localized: "Find the files that take up the most space and the ones you haven’t opened in a long time.",
                    bundle: .module,
                    comment: "Introduction of the large files feature."
                ),
                theme: theme
            )
            Button(action: onScan) {
                Text("Scan", bundle: .module, comment: "Button that starts looking for large files.")
            }
            .buttonStyle(GlowButtonStyle(theme: theme, shape: .circle(diameter: 132)))
            .keyboardShortcut(.defaultAction)
        }
    }
}
