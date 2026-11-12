import CleanMacCore
import CleanMacUI
import Foundation
import SwiftUI

/// Entry point of the privacy feature for the app shell.
@MainActor
public final class PrivacyModule: FeatureModule {
    public let id = "privacy"
    public let title = String(localized: "Privacy", bundle: .module, comment: "Feature name in the sidebar.")
    public let symbolName = "hand.raised.fill"
    public let theme = FeatureTheme.privacy
    public let section = FeatureSection.cleanup

    private let viewModel: PrivacyViewModel

    public init(viewModel: PrivacyViewModel) {
        self.viewModel = viewModel
    }

    public func makeView() -> AnyView {
        AnyView(PrivacyView(viewModel: viewModel, theme: theme))
    }
}

public extension PrivacyModule {
    /// Module wired to the current user's Library, the installed browsers and the Trash.
    static func live() -> PrivacyModule {
        let reader = LocalDirectoryReader()
        let scanner = BrowserCacheScanner(
            library: FileManager.default.homeDirectoryForCurrentUser.appending(path: "Library"),
            appLocator: LaunchServicesAppLocator(),
            reader: reader,
            sizer: AllocatedSizeCalculator()
        )
        let viewModel = PrivacyViewModel(
            scanner: scanner,
            runningApps: WorkspaceRunningApps(),
            cleanupService: CleanupService(remover: MissingItemTolerantRemover(TrashItemRemover()))
        )
        return PrivacyModule(viewModel: viewModel)
    }
}
