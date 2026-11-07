import CleanMacUI
import SwiftUI

/// Shown while the selected items are moved to the Trash.
struct JunkCleaningView: View {
    let theme: FeatureTheme

    var body: some View {
        VStack(spacing: 24) {
            ProgressView()
                .controlSize(.large)
                .tint(theme.primary)
            Text("Moviendo a la Papelera…")
                .font(.title3.weight(.medium))
        }
    }
}
