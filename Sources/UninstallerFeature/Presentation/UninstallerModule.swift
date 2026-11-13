import CleanMacCore
import CleanMacUI
import Foundation
import SwiftUI

/// Entry point of the uninstaller feature for the app shell.
@MainActor
public final class UninstallerModule: FeatureModule {
    public let id = "uninstaller"
    public let title = String(localized: "Uninstaller", bundle: .module, comment: "Feature name in the sidebar.")
    public let symbolName = "app.badge.checkmark"
    public let theme = FeatureTheme.uninstaller
    public let section = FeatureSection.applications

    private let viewModel: UninstallerViewModel

    public init(viewModel: UninstallerViewModel) {
        self.viewModel = viewModel
    }

    public func makeView() -> AnyView {
        AnyView(UninstallerView(viewModel: viewModel, theme: theme))
    }

    /// Focuses the app at `url`, loading the app list first if needed.
    public func show(itemAt url: URL) {
        viewModel.focusApp(at: url)
    }

    /// Offers to show here an app that another feature lists, such as one of the disk map.
    public var itemActions: [FeatureItemAction] {
        [
            FeatureItemAction(
                featureID: id,
                itemKind: .app,
                title: String(
                    localized: "Show in Uninstaller",
                    bundle: .module,
                    comment: "Entry of the context menu of an app listed by another feature, such as the disk map. It shows the app in the Uninstaller."
                ),
                symbolName: symbolName
            )
        ]
    }
}

public extension UninstallerModule {
    /// CleanMac's own bundle identifier, so it never offers to uninstall itself.
    static let ownBundleIdentifier = "io.github.cleanmac"

    /// Module wired to the apps and Library of the current user.
    static func live() -> UninstallerModule {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let scanner = InstalledAppScanner(
            applicationFolders: [URL(filePath: "/Applications"), home.appending(path: "Applications")],
            locator: FileSystemAppLocator(),
            infoReader: InfoPlistReader(),
            leftoverLocations: LeftoverCatalog.userLocations(home: home),
            reader: LocalDirectoryReader(),
            sizer: AllocatedSizeCalculator(),
            excludedBundleIDs: [ownBundleIdentifier]
        )
        let viewModel = UninstallerViewModel(
            scanner: scanner,
            runningApps: WorkspaceRunningApps(),
            cleanupService: CleanupService(remover: FallbackItemRemover.trashWithFinderFallback)
        )
        return UninstallerModule(viewModel: viewModel)
    }
}
