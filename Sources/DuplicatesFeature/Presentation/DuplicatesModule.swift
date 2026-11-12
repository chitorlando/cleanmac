import CleanMacCore
import CleanMacUI
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

    public init(viewModel: DuplicatesViewModel) {
        self.viewModel = viewModel
    }

    public func makeView() -> AnyView {
        AnyView(DuplicatesView(viewModel: viewModel, theme: theme))
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
}

public extension DuplicatesModule {
    /// Module that walks the current user's home folder and moves copies to the Trash.
    static func live() -> DuplicatesModule {
        let excludedDirectories = [FileSystemWalker.userLibrary]
        let scanner = DuplicateScanner(
            home: FileManager.default.homeDirectoryForCurrentUser,
            walker: FileSystemWalker(excludedDirectories: excludedDirectories),
            excludedDirectories: excludedDirectories
        )
        let viewModel = DuplicatesViewModel(
            scanner: scanner,
            cleanupService: CleanupService(remover: TrashItemRemover())
        )
        return DuplicatesModule(viewModel: viewModel)
    }
}
