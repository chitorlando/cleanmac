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
                title: "Basura del sistema",
                subtitle: "Libera espacio eliminando cachés, registros y restos de desarrollo que ya no necesitas.",
                theme: theme
            )
            Button("Escanear", action: onScan)
                .buttonStyle(GlowButtonStyle(theme: theme, shape: .circle(diameter: 132)))
                .keyboardShortcut(.defaultAction)
        }
    }
}
