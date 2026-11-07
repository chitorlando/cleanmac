import CleanMacUI
import SwiftUI

/// Bottom bar with the clean and rescan actions.
struct JunkReviewActionBar: View {
    let selectedSize: Int64
    let canClean: Bool
    let theme: FeatureTheme
    let onRescan: () -> Void
    let onClean: () -> Void

    var body: some View {
        HStack {
            Button("Volver a escanear", action: onRescan)
                .buttonStyle(.borderless)
                .foregroundStyle(.secondary)
            Spacer()
            Button("Limpiar \(selectedSize.formattedByteCount)", action: onClean)
                .buttonStyle(GlowButtonStyle(theme: theme, shape: .capsule))
                .disabled(!canClean)
                .keyboardShortcut(.defaultAction)
        }
    }
}
