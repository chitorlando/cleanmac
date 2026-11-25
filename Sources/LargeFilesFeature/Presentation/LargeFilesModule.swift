import CleanMacCore
import CleanMacUI
import Combine
import Foundation
import SwiftUI

/// Entry point of the large files feature for the app shell.
@MainActor
public final class LargeFilesModule: FeatureModule {
    public let id = "large-files"
    public let title = String(localized: "Large Files", bundle: .module, comment: "Feature name in the sidebar.")
    public let symbolName = "doc.richtext"
    public let theme = FeatureTheme.largeFiles
    public let section = FeatureSection.files

    private let viewModel: LargeFilesViewModel
    private let preferences: Preferences
    private var minimumSizeChanges: AnyCancellable?
    private var excludedFolderChanges: AnyCancellable?

    /// - Parameter preferences: Where the user chooses the smallest size of the files to find
    ///   and the folders to leave out, which each new scan of `viewModel` follows from now on.
    public init(viewModel: LargeFilesViewModel, preferences: Preferences) {
        self.viewModel = viewModel
        self.preferences = preferences
        viewModel.minimumSizeForNextScan = preferences.value(of: LargeFilesSettings.minimumSize)
        minimumSizeChanges = preferences.changes(of: LargeFilesSettings.minimumSize)
            .sink { [viewModel] size in viewModel.minimumSizeForNextScan = size }
        viewModel.excludedFoldersForNextScan = ScanSettings.folders(at: preferences.value(of: ScanSettings.excludedFolders))
        excludedFolderChanges = preferences.changes(of: ScanSettings.excludedFolders)
            .sink { [viewModel] paths in viewModel.excludedFoldersForNextScan = ScanSettings.folders(at: paths) }
    }

    public func makeView() -> AnyView {
        AnyView(LargeFilesView(viewModel: viewModel, theme: theme))
    }

    public var settings: [SettingsItem] {
        [
            SettingsItem(id: LargeFilesSettings.minimumSize.key, section: .analysis) { [preferences] in
                MinimumSizePicker(preferences: preferences)
            }
        ]
    }

    /// Looks for large files in a folder that another feature shows, such as one of the disk map.
    public var itemActions: [FeatureItemAction] {
        [
            FeatureItemAction(
                featureID: id,
                itemKind: .folder,
                title: String(
                    localized: "Find Large Files in This Folder",
                    bundle: .module,
                    comment: "Action offered for a folder shown by another feature, such as in the disk map. It looks for large files only in that folder."
                ),
                symbolName: "doc.text.magnifyingglass"
            )
        ]
    }

    /// Scans only the folder at `url`. See `LargeFilesViewModel.scanFolder(at:)` for what
    /// happens in each phase and which folders are ignored.
    public func show(itemAt url: URL) {
        viewModel.scanFolder(at: url)
    }

    /// Takes only the folders that `show(itemAt:)` doesn't ignore.
    public func canShow(itemAt url: URL) -> Bool {
        viewModel.canScanFolder(at: url)
    }
}

public extension LargeFilesModule {
    /// Module that walks the current user's home folder and moves files to the Trash.
    ///
    /// `~/Library` is always left out, as other features take care of it, and so are the
    /// folders the user chooses. The scanner gives the walker of each scan the folders its
    /// scope policy leaves out, so a scan limited to one folder can't start inside them.
    ///
    /// - Parameter preferences: See `init(viewModel:preferences:)`.
    static func live(preferences: Preferences) -> LargeFilesModule {
        let scanner = LargeFileScanner(scopePolicy: .currentUserHome)
        let viewModel = LargeFilesViewModel(
            scanner: scanner,
            cleanupService: CleanupService(remover: TrashItemRemover())
        )
        return LargeFilesModule(viewModel: viewModel, preferences: preferences)
    }
}
