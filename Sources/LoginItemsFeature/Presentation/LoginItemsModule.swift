import CleanMacCore
import CleanMacUI
import Foundation
import SwiftUI

/// Entry point of the login items feature for the app shell.
@MainActor
public final class LoginItemsModule: FeatureModule {
    public let id = "login-items"
    public let title = String(localized: "Login Items", bundle: .module, comment: "Feature name in the sidebar.")
    public let symbolName = "power"
    public let theme = FeatureTheme.loginItems
    public let section = FeatureSection.performance

    private let viewModel: LoginItemsViewModel

    public init(viewModel: LoginItemsViewModel) {
        self.viewModel = viewModel
    }

    public func makeView() -> AnyView {
        AnyView(LoginItemsView(viewModel: viewModel, theme: theme))
    }
}

public extension LoginItemsModule {
    /// Module that reads the real launchd folders and moves the user's agents to the Trash.
    static func live() -> LoginItemsModule {
        let reader = LocalDirectoryReader()
        let scanner = LoginItemScanner(
            folders: LaunchFolder.standard(home: FileManager.default.homeDirectoryForCurrentUser),
            reader: reader,
            sizer: AllocatedSizeCalculator(),
            attributor: LoginItemAttributor(appLocator: LaunchServicesAppLocator(), reader: reader)
        )
        let viewModel = LoginItemsViewModel(
            scanner: scanner,
            cleanupService: CleanupService(remover: TrashItemRemover()),
            settingsOpener: SystemSettingsOpener()
        )
        return LoginItemsModule(viewModel: viewModel)
    }
}
