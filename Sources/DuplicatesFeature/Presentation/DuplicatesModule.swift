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
}

public extension DuplicatesModule {
    /// Module that walks the current user's home folder and moves copies to the Trash.
    static func live() -> DuplicatesModule {
        let scanner = DuplicateScanner(
            root: FileManager.default.homeDirectoryForCurrentUser,
            walker: FileSystemWalker()
        )
        let viewModel = DuplicatesViewModel(
            scanner: scanner,
            cleanupService: CleanupService(remover: TrashItemRemover())
        )
        return DuplicatesModule(viewModel: viewModel)
    }
}
