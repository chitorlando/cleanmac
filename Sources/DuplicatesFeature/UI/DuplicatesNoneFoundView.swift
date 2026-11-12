import CleanMacUI
import Foundation
import SwiftUI

/// Shown when the scan found no duplicates, or every duplicate has been removed.
struct DuplicatesNoneFoundView: View {
    let wasStoppedEarly: Bool
    /// The folder the scan was limited to, or `nil` when it covered the whole home folder.
    let folder: URL?
    let theme: FeatureTheme
    let onScanAgain: () -> Void

    var body: some View {
        VStack(spacing: 40) {
            HeroHeader(
                symbolName: "sparkles",
                title: String(localized: "No Duplicates", bundle: .module, comment: "Title shown when no duplicate files were found."),
                subtitle: subtitle,
                theme: theme
            )
            Button(action: onScanAgain) {
                Text("Scan Again", bundle: .module, comment: "Button that repeats the duplicates scan.")
            }
            .buttonStyle(GlowButtonStyle(theme: theme, shape: .capsule))
            .keyboardShortcut(.defaultAction)
        }
    }

    private var subtitle: String {
        if wasStoppedEarly {
            String(
                localized: "The scan was stopped before finding any duplicates.",
                bundle: .module,
                comment: "Message shown when the user stopped the scan before any duplicate was found."
            )
        } else if let folder {
            String(
                localized: "No file of \(DuplicateScanner.defaultMinimumSize.formattedByteCount) or more in the folder “\(folder.folderDisplayName)” has an identical copy.",
                bundle: .module,
                comment: "Message shown when a complete scan of one folder found no duplicates. The arguments are the smallest size compared, such as “1 MB”, and the name of the folder."
            )
        } else {
            String(
                localized: "No file of \(DuplicateScanner.defaultMinimumSize.formattedByteCount) or more in your home folder has an identical copy.",
                bundle: .module,
                comment: "Message shown when a complete scan found no duplicates. The argument is the smallest size compared, such as “1 MB”."
            )
        }
    }
}
