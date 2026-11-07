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

    private let viewModel: LargeFilesViewModel

    public init(viewModel: LargeFilesViewModel) {
        self.viewModel = viewModel
    }

    public func makeView() -> AnyView {
        AnyView(LargeFilesView(viewModel: viewModel, theme: theme))
    }
}

public extension LargeFilesModule {
    /// Module that walks the current user's home folder and moves files to the Trash.
    static func live() -> LargeFilesModule {
        let scanner = LargeFileScanner(
            root: FileManager.default.homeDirectoryForCurrentUser,
            walker: FileSystemWalker()
        )
        let viewModel = LargeFilesViewModel(
            scanner: scanner,
            cleanupService: CleanupService(remover: TrashItemRemover())
        )
        return LargeFilesModule(viewModel: viewModel)
    }
}
