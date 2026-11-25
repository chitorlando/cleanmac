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

    /// Offers to list the login items of an app that another feature shows, such as one of
    /// the uninstaller.
    public var itemActions: [FeatureItemAction] {
        [
            FeatureItemAction(
                featureID: id,
                itemKind: .app,
                title: String(
                    localized: "Show Login Items",
                    bundle: .module,
                    comment: "Entry of the context menu of an app listed by another feature, such as the uninstaller. It shows only the login items of that app."
                ),
                symbolName: symbolName
            )
        ]
    }

    /// Lists only the login items of the app at `url`, reading them first if they weren't yet.
    public func show(itemAt url: URL) {
        viewModel.showItems(ofAppAt: url)
    }

    /// Takes every app bundle, with login items or not, without reading anything.
    public func canShow(itemAt url: URL) -> Bool {
        viewModel.canShowItems(ofAppAt: url)
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
            attributor: LoginItemAttributor(appLocator: LaunchServicesAppLocator(), reader: reader),
            overrides: LaunchdOverrideFiles()
        )
        let viewModel = LoginItemsViewModel(
            scanner: scanner,
            cleanupService: CleanupService(remover: TrashItemRemover()),
            settingsOpener: SystemSettingsOpener()
        )
        return LoginItemsModule(viewModel: viewModel)
    }
}
