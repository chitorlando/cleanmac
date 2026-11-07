import CleanMacUI
import SwiftUI

/// Shown when the scan finds nothing to remove.
struct JunkAllCleanView: View {
    let theme: FeatureTheme
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: 40) {
            HeroHeader(
                symbolName: "sparkles",
                title: "Todo limpio",
                subtitle: "No hemos encontrado basura que eliminar.",
                theme: theme
            )
            Button("Listo", action: onDone)
                .buttonStyle(GlowButtonStyle(theme: theme, shape: .capsule))
                .keyboardShortcut(.defaultAction)
        }
    }
}
