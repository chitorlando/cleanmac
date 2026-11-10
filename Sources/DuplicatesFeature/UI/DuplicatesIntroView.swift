import CleanMacUI
import SwiftUI

/// Welcome state with the main scan button.
struct DuplicatesIntroView: View {
    let theme: FeatureTheme
    let onScan: () -> Void

    var body: some View {
        VStack(spacing: 48) {
            HeroHeader(
                symbolName: "doc.on.doc.fill",
                title: String(localized: "Duplicates", bundle: .module, comment: "Feature name in the sidebar."),
                subtitle: String(
                    localized: "Find identical copies of your files and choose which ones to move to the Trash.",
                    bundle: .module,
                    comment: "Introduction of the duplicates feature."
                ),
                theme: theme
            )
            Button(action: onScan) {
                Text("Scan", bundle: .module, comment: "Button that starts looking for duplicate files.")
            }
            .buttonStyle(GlowButtonStyle(theme: theme, shape: .circle(diameter: 132)))
            .keyboardShortcut(.defaultAction)
        }
    }
}
