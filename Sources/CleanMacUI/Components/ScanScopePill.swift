import Foundation
import SwiftUI

/// Pill shown while a scan is limited to one folder: the name of the folder as Finder shows
/// it, its path as a tooltip and a button that scans the whole home folder instead.
///
/// It has the colors of `StatusBadge`, which can't hold an icon or a button. The name stays
/// on one line and is cut in the middle when it doesn't fit, so the pill is never wider than
/// the room it gets, such as in the smallest window.
///
/// The screens that show it are drawn again with every step of a scan, and the name of the
/// folder is asked to the system, which reads the disk. Two pills are equal when they show
/// the same, so wrapped in `.equatable()` the pill only asks when the folder changes.
public struct ScanScopePill: View, Equatable {
    private static let maximumWidth: CGFloat = 420
    /// Side of the area that takes the click on the button, larger than its symbol.
    private static let buttonSize: CGFloat = 20

    private let folder: URL
    private let theme: FeatureTheme
    private let onScanHome: () -> Void

    /// - Parameters:
    ///   - folder: The folder the scan is limited to.
    ///   - onScanHome: Called by the button of the pill, to scan the whole home folder.
    public init(folder: URL, theme: FeatureTheme, onScanHome: @escaping () -> Void) {
        self.folder = folder
        self.theme = theme
        self.onScanHome = onScanHome
    }

    public var body: some View {
        HStack(spacing: 6) {
            label
            scanHomeButton
        }
        .font(.callout.weight(.medium))
        .padding(.leading, 12)
        .padding(.trailing, 6)
        .padding(.vertical, 3)
        .background(theme.primary.opacity(0.16), in: .pill)
        .overlay(Capsule.pill.strokeBorder(theme.primary.opacity(0.35), lineWidth: 1))
        .frame(maxWidth: Self.maximumWidth)
    }

    /// Compares what the pill shows. The action is left out: it always scans the home folder.
    public nonisolated static func == (lhs: ScanScopePill, rhs: ScanScopePill) -> Bool {
        lhs.folder == rhs.folder
            && lhs.theme.primary == rhs.theme.primary
            && lhs.theme.secondary == rhs.theme.secondary
    }

    private var label: some View {
        HStack(spacing: 6) {
            Image(systemName: "folder.fill")
                .accessibilityHidden(true)
            Text(
                "Only in: \(folder.folderDisplayName)",
                bundle: .module,
                comment: "Pill shown while a scan is limited to one folder. The argument is the name of the folder."
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
                .foregroundStyle(.secondary)
                .frame(width: Self.buttonSize, height: Self.buttonSize)
                .contentShape(.circle)
        }
        .buttonStyle(.plain)
        .help(scanHomeTitle)
        .accessibilityLabel(scanHomeTitle)
    }

    private var scanHomeTitle: Text {
        Text(
            "Scan the Whole Home Folder",
            bundle: .module,
            comment: "Tooltip and accessibility label of the button, on the pill that names the folder a scan is limited to, that scans the whole home folder instead."
        )
    }
}
