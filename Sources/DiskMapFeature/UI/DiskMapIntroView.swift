import CleanMacUI
import SwiftUI

/// Welcome state with the main scan button and a word on Full Disk Access.
struct DiskMapIntroView: View {
    let theme: FeatureTheme
    let onScan: () -> Void

    var body: some View {
        VStack(spacing: 28) {
            HeroHeader(
                symbolName: "chart.pie.fill",
                title: String(localized: "Disk Map", bundle: .module, comment: "Feature name in the sidebar."),
                subtitle: String(
                    localized: "See which folders take up the most space, explore them and free up what you no longer need.",
                    bundle: .module,
                    comment: "Introduction of the disk map feature."
                ),
                theme: theme
            )
            Button(action: onScan) {
                Text("Scan", bundle: .module, comment: "Button that starts measuring the home folder for the disk map.")
            }
            .buttonStyle(GlowButtonStyle(theme: theme, shape: .circle(diameter: 132)))
            .keyboardShortcut(.defaultAction)
            FullDiskAccessNote()
        }
    }
}
