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
            Button(action: onRescan) {
                Text("Scan Again", bundle: .module, comment: "Button that repeats the junk scan.")
            }
            .buttonStyle(.borderless)
            .foregroundStyle(.secondary)

            Spacer()

            Button(action: onClean) {
                Text(
                    "Clean \(selectedSize.formattedByteCount)",
                    bundle: .module,
                    comment: "Button that removes the selected junk. The argument is a size, such as “1.2 GB”."
                )
            }
            .buttonStyle(GlowButtonStyle(theme: theme, shape: .capsule))
            .disabled(!canClean)
            .keyboardShortcut(.defaultAction)
        }
    }
}
