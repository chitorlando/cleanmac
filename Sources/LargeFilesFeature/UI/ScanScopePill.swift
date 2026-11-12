import CleanMacUI
import Foundation
import SwiftUI

/// Small capsule that names the folder a scan is limited to, with a button that scans the
/// whole home folder instead.
///
/// It shows the name of the folder as Finder does and gives its path as a tooltip. The name
/// stays on one line and is cut in the middle when it doesn't fit, so the pill is never wider
/// than the room it gets, such as in the smallest window.
///
/// The screens that show it are drawn again with every file a scan finds, and the name of
/// the folder is asked to the system, which reads the disk. Two pills are equal when they name
/// the same folder, so wrapped in `.equatable()` the pill only asks when the folder changes.
struct ScanScopePill: View, Equatable {
    let folder: URL
    let theme: FeatureTheme
    let onScanHome: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            label
            scanHomeButton
        }
        .font(.caption.weight(.semibold))
        .padding(.leading, 10)
        .padding(.trailing, 6)
        .padding(.vertical, 4)
        .background(theme.primary.opacity(0.16), in: Self.shape)
        .overlay(Self.shape.strokeBorder(theme.primary.opacity(0.35), lineWidth: 1))
    }

    /// Compares what the pill shows. The action is left out: it always scans the home folder.
    nonisolated static func == (lhs: ScanScopePill, rhs: ScanScopePill) -> Bool {
        lhs.folder == rhs.folder
            && lhs.theme.primary == rhs.theme.primary
            && lhs.theme.secondary == rhs.theme.secondary
    }

    /// A capsule with perfectly round ends. The default one leaves seams at both ends when stroked.
    private static var shape: Capsule { Capsule(style: .circular) }

    private var label: some View {
        HStack(spacing: 5) {
            Image(systemName: "folder.fill")
                .accessibilityHidden(true)
            Text(
                "Only in: \(folder.folderDisplayName)",
                bundle: .module,
                comment: "Pill shown while the scan is limited to one folder. The argument is the name of the folder."
            )
            .lineLimit(1)
            .truncationMode(.middle)
        }
        .foregroundStyle(theme.primary)
        .help(Text(verbatim: folder.tildeAbbreviatedPath))
        .accessibilityElement(children: .combine)
    }

    private var scanHomeButton: some View {
        Button(action: onScanHome) {
            Image(systemName: "xmark.circle.fill")
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .buttonStyle(.plain)
        .help(scanHomeLabel)
        .accessibilityLabel(scanHomeLabel)
    }

    private var scanHomeLabel: Text {
        Text(
            "Scan the Whole Home Folder",
            bundle: .module,
            comment: "Tooltip and accessibility label of the button, in the pill that names the folder a scan is limited to, that scans the whole home folder instead."
        )
    }
}
