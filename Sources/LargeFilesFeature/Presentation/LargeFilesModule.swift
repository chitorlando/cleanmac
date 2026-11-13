import CleanMacCore
import CleanMacUI
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

    public init(viewModel: LargeFilesViewModel) {
        self.viewModel = viewModel
    }

    public func makeView() -> AnyView {
        AnyView(LargeFilesView(viewModel: viewModel, theme: theme))
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
}

public extension LargeFilesModule {
    /// Module that walks the current user's home folder and moves files to the Trash.
    ///
    /// `~/Library` is left out, as other features take care of it. The walker and the scope
    /// policy get the same excluded folders, so a scan limited to one folder can't start inside them.
    static func live() -> LargeFilesModule {
        let excludedDirectories = [FileSystemWalker.userLibrary]
        let scanner = LargeFileScanner(
            scopePolicy: ScanScopePolicy(
                home: FileManager.default.homeDirectoryForCurrentUser,
                excludedDirectories: excludedDirectories
            ),
            walker: FileSystemWalker(excludedDirectories: excludedDirectories)
        )
        let viewModel = LargeFilesViewModel(
            scanner: scanner,
            cleanupService: CleanupService(remover: TrashItemRemover())
        )
        return LargeFilesModule(viewModel: viewModel)
    }
}
