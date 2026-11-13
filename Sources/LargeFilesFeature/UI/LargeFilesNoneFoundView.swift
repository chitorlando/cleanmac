import CleanMacUI
import Foundation
import SwiftUI

/// Shown when the scan found no large files.
struct LargeFilesNoneFoundView: View {
    let wasStoppedEarly: Bool
    /// Smallest size the scan looked for, in bytes.
    let minimumSize: Int64
    /// Folder the scan was limited to, or `nil` when it covered the whole home folder.
    let scopeFolder: URL?
    let theme: FeatureTheme
    let onScanAgain: () -> Void
    /// Scans the whole home folder, leaving the folder the scan was limited to.
    let onScanHome: () -> Void

    var body: some View {
        VStack(spacing: 40) {
            VStack(spacing: 18) {
                HeroHeader(
                    symbolName: "sparkles",
                    title: String(localized: "No Large Files", bundle: .module, comment: "Title shown when no large files were found."),
                    subtitle: subtitle,
                    theme: theme
                )
                if let scopeFolder {
                    ScanScopePill(folder: scopeFolder, theme: theme, onScanHome: onScanHome)
                        .equatable()
                }
            }
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
        } else if let scopeFolder {
            String(
                localized: "Nothing in the folder “\(scopeFolder.folderDisplayName)” takes up more than \(minimumSize.formattedByteCount).",
                bundle: .module,
                comment: "Message shown when a complete scan limited to one folder found no large files. The arguments are the name of the folder and the smallest size looked for, such as “50 MB”."
            )
        } else {
            String(
                localized: "Nothing in your home folder takes up more than \(minimumSize.formattedByteCount).",
                bundle: .module,
                comment: "Message shown when a complete scan found no large files. The argument is the smallest size looked for, such as “50 MB”."
            )
        }
    }
}
