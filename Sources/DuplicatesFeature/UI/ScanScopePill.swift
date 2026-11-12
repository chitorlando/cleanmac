import CleanMacUI
import Foundation
import SwiftUI

/// Pill shown while the screen is limited to one folder: its name, its path as a tooltip and
/// a button that goes back to the whole home folder.
///
/// It has the colors of `StatusBadge`, which can't hold an icon or a button. A long name is
/// shortened in the middle, so the pill fits the narrowest window.
///
/// Two pills are equal when they show the same, so wrapped in `.equatable()` the name of the
/// folder is only asked for when the folder changes, not on every step of a scan.
struct ScanScopePill: View, Equatable {
    private static let maximumWidth: CGFloat = 420

    let folder: URL
    let theme: FeatureTheme
    let onScanHome: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            label
            Button(action: onScanHome) {
                Image(systemName: "xmark.circle.fill")
                    .frame(width: 20, height: 20)
                    .contentShape(.circle)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(scanHomeTitle)
            .help(scanHomeTitle)
        }
        .font(.callout.weight(.medium))
        .foregroundStyle(theme.primary)
        .padding(.leading, 12)
        .padding(.trailing, 6)
        .padding(.vertical, 3)
        .background(theme.primary.opacity(0.16), in: Capsule(style: .circular))
        .overlay(Capsule(style: .circular).strokeBorder(theme.primary.opacity(0.35), lineWidth: 1))
        .frame(maxWidth: Self.maximumWidth)
    }

    private var label: some View {
        HStack(spacing: 6) {
            Image(systemName: "folder.fill")
                .accessibilityHidden(true)
            Text(
                "Only in: \(folder.folderDisplayName)",
                bundle: .module,
                comment: "Label of the pill shown while only one folder is scanned. The argument is the name of the folder."
            )
            .lineLimit(1)
            .truncationMode(.middle)
        }
        .help(Text(verbatim: path))
    }

    private var scanHomeTitle: Text {
        Text(
            "Scan the Whole Home Folder",
            bundle: .module,
            comment: "Button on the pill of the folder being scanned. It leaves the folder and scans the whole home folder."
        )
    }

    /// Path of the folder with the home folder shortened to `~`.
    private var path: String {
        (folder.path as NSString).abbreviatingWithTildeInPath
    }

    /// Compares what the pill shows. The action is left out: it always scans the home folder.
    nonisolated static func == (lhs: ScanScopePill, rhs: ScanScopePill) -> Bool {
        lhs.folder == rhs.folder
            && lhs.theme.primary == rhs.theme.primary
            && lhs.theme.secondary == rhs.theme.secondary
    }
}
