import Foundation
import SwiftUI

/// `ScopePill` shown while a scan is limited to one folder: the name of the folder as Finder
/// shows it, its path as a tooltip and a button that scans the whole home folder instead.
///
/// The screens that show it are drawn again with every step of a scan, and the name of the
/// folder is asked to the system, which reads the disk. Two pills are equal when they show
/// the same, so wrapped in `.equatable()` the pill only asks when the folder changes.
public struct ScanScopePill: View, Equatable {
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
        ScopePill(
            symbolName: "folder.fill",
            label: Text(
                "Only in: \(folder.folderDisplayName)",
                bundle: .module,
                comment: "Pill shown while a scan is limited to one folder. The argument is the name of the folder."
            ),
            help: Text(verbatim: folder.tildeAbbreviatedPath),
            clearTitle: Text(
                "Scan the Whole Home Folder",
                bundle: .module,
                comment: "Tooltip and accessibility label of the button, on the pill that names the folder a scan is limited to, that scans the whole home folder instead."
            ),
            theme: theme,
            onClear: onScanHome
        )
    }

    /// Compares what the pill shows. The action is left out: it always scans the home folder.
    public nonisolated static func == (lhs: ScanScopePill, rhs: ScanScopePill) -> Bool {
        lhs.folder == rhs.folder
            && lhs.theme.primary == rhs.theme.primary
            && lhs.theme.secondary == rhs.theme.secondary
    }
}
