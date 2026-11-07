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
            Text("Moving to the Trash…", bundle: .module, comment: "Status shown while cleaning.")
                .font(.title3.weight(.medium))
        }
    }
}
