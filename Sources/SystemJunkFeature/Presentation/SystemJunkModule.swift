import CleanMacCore
import CleanMacUI
import Foundation
import SwiftUI

/// Entry point of the system junk feature for the app shell.
@MainActor
public final class SystemJunkModule: FeatureModule {
    public let id = "system-junk"
    public let title = String(localized: "System Junk", bundle: .module, comment: "Feature name in the sidebar.")
    public let symbolName = "trash.fill"
    public let theme = FeatureTheme.systemJunk
    public let section = FeatureSection.cleanup

    private let viewModel: SystemJunkViewModel
    /// Paths of the folders whose items the feature offers as junk, spelled the standard way.
    private let junkFolderPaths: Set<String>

    /// - Parameter junkFolders: Folders whose items the feature offers as junk, such as
    ///   `~/Library/Caches`. Other features that show them offer to review them here.
    public init(viewModel: SystemJunkViewModel, junkFolders: [URL] = []) {
        self.viewModel = viewModel
        junkFolderPaths = Set(junkFolders.map(\.standardizedFileURL.path))
    }

    public func makeView() -> AnyView {
        AnyView(SystemJunkView(viewModel: viewModel, theme: theme))
    }

    /// Offers to review the junk of a folder that another feature shows, such as
    /// `~/Library/Caches` in the disk map.
    public var itemActions: [FeatureItemAction] {
        [
            FeatureItemAction(
                featureID: id,
                itemKind: .folder,
                title: String(
                    localized: "Review in System Junk",
                    bundle: .module,
                    comment: "Entry of the context menu of a folder whose junk System Junk cleans, such as the caches folder, shown by another feature such as the disk map. It opens System Junk."
                ),
                symbolName: symbolName
            )
        ]
    }

    /// Takes only the folders whose items it offers as junk.
    public func canShow(itemAt url: URL) -> Bool {
        junkFolderPaths.contains(url.standardizedFileURL.path)
    }

    /// Looks for junk, unless it already has, so the folder's junk is there to review.
    public func show(itemAt url: URL) {
        guard viewModel.phase == .idle else { return }
        viewModel.startScan()
    }
}

public extension SystemJunkModule {
    /// Module wired to the real file system of the current user.
    static func live() -> SystemJunkModule {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let scanners = JunkCatalog.scanners(
            home: home,
            reader: LocalDirectoryReader(),
            sizer: AllocatedSizeCalculator()
        )
        let viewModel = SystemJunkViewModel(
            scanService: JunkScanService(scanners: scanners),
            cleanupService: CleanupService(remover: MissingItemTolerantRemover(TrashItemRemover()))
        )
        return SystemJunkModule(viewModel: viewModel, junkFolders: JunkCatalog.locations(home: home))
    }
}
