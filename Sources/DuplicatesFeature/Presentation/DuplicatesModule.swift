import CleanMacCore
import CleanMacUI
import Combine
import Foundation
import SwiftUI

/// Entry point of the duplicates feature for the app shell.
@MainActor
public final class DuplicatesModule: FeatureModule {
    public let id = "duplicates"
    public let title = String(localized: "Duplicates", bundle: .module, comment: "Feature name in the sidebar.")
    public let symbolName = "doc.on.doc.fill"
    public let theme = FeatureTheme.duplicates
    public let section = FeatureSection.files

    private let viewModel: DuplicatesViewModel
    private let preferences: Preferences
    private var minimumSizeChanges: AnyCancellable?
    private var excludedFolderChanges: AnyCancellable?

    /// - Parameter preferences: Where the user chooses the smallest size of the files to
    ///   compare and the folders to leave out, which each new scan of `viewModel` follows
    ///   from now on.
    public init(viewModel: DuplicatesViewModel, preferences: Preferences) {
        self.viewModel = viewModel
        self.preferences = preferences
        viewModel.minimumSizeForNextScan = preferences.value(of: DuplicatesSettings.minimumSize)
        minimumSizeChanges = preferences.changes(of: DuplicatesSettings.minimumSize)
            .sink { [viewModel] size in viewModel.minimumSizeForNextScan = size }
        viewModel.excludedFoldersForNextScan = ScanSettings.folders(at: preferences.value(of: ScanSettings.excludedFolders))
        excludedFolderChanges = preferences.changes(of: ScanSettings.excludedFolders)
            .sink { [viewModel] paths in viewModel.excludedFoldersForNextScan = ScanSettings.folders(at: paths) }
    }

    public func makeView() -> AnyView {
        AnyView(DuplicatesView(viewModel: viewModel, theme: theme))
    }

    public var settings: [SettingsItem] {
        [
            SettingsItem(id: DuplicatesSettings.minimumSize.key, section: .analysis) { [preferences] in
                MinimumSizePicker(preferences: preferences)
            }
        ]
    }

    /// Offers to look for duplicates only in a folder that another feature shows.
    public var itemActions: [FeatureItemAction] {
        [
            FeatureItemAction(
                featureID: id,
                itemKind: .folder,
                title: String(
                    localized: "Find Duplicates in This Folder",
                    bundle: .module,
                    comment: "Action offered on a folder shown by another feature, such as the disk map. It looks for duplicate files only in that folder."
                ),
                symbolName: "doc.on.doc"
            )
        ]
    }

    /// Looks for duplicates only in the folder at `url`. Anything that can't be scanned on
    /// its own is ignored, such as a file, a symbolic link or a folder inside `~/Library`.
    public func show(itemAt url: URL) {
        viewModel.scanFolder(at: url)
    }

    /// Takes only the folders that `show(itemAt:)` doesn't ignore.
    public func canShow(itemAt url: URL) -> Bool {
        viewModel.canScanFolder(at: url)
    }
}

public extension DuplicatesModule {
    /// Module that walks the current user's home folder and moves copies to the Trash.
    ///
    /// `~/Library` is always left out, as other features take care of it, and so are the
    /// folders the user chooses.
    ///
    /// - Parameter preferences: See `init(viewModel:preferences:)`.
    static func live(preferences: Preferences) -> DuplicatesModule {
        let scanner = DuplicateScanner(scopePolicy: .currentUserHome)
        let viewModel = DuplicatesViewModel(
            scanner: scanner,
            cleanupService: CleanupService(remover: TrashItemRemover())
        )
        return DuplicatesModule(viewModel: viewModel, preferences: preferences)
    }
}
