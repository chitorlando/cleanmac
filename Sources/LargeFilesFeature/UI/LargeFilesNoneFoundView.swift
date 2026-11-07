import CleanMacUI
import SwiftUI

/// Shown when the scan found no large files.
struct LargeFilesNoneFoundView: View {
    let wasStoppedEarly: Bool
    let theme: FeatureTheme
    let onScanAgain: () -> Void

    var body: some View {
        VStack(spacing: 40) {
            HeroHeader(
                symbolName: "sparkles",
                title: String(localized: "No Large Files", bundle: .module, comment: "Title shown when no large files were found."),
                subtitle: subtitle,
                theme: theme
            )
            Button(action: onScanAgain) {
                Text("Scan Again", bundle: .module, comment: "Button that repeats the large files scan.")
            }
            .buttonStyle(GlowButtonStyle(theme: theme, shape: .capsule))
            .keyboardShortcut(.defaultAction)
        }
    }

    private var subtitle: String {
        if wasStoppedEarly {
            String(
                localized: "The scan was stopped before finding any large files.",
                bundle: .module,
                comment: "Message shown when the user stopped the scan before any large file was found."
            )
        } else {
            String(
                localized: "Nothing in your home folder takes up more than 50 MB.",
                bundle: .module,
                comment: "Message shown when a complete scan found no large files."
            )
        }
    }
}
