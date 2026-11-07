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

    public init(viewModel: SystemJunkViewModel) {
        self.viewModel = viewModel
    }

    public func makeView() -> AnyView {
        AnyView(SystemJunkView(viewModel: viewModel, theme: theme))
    }
}

public extension SystemJunkModule {
    /// Module wired to the real file system of the current user.
    static func live() -> SystemJunkModule {
        let scanners = JunkCatalog.scanners(
            home: FileManager.default.homeDirectoryForCurrentUser,
            reader: LocalDirectoryReader(),
            sizer: AllocatedSizeCalculator()
        )
        let viewModel = SystemJunkViewModel(
            scanService: JunkScanService(scanners: scanners),
            cleanupService: CleanupService(remover: TrashItemRemover())
        )
        return SystemJunkModule(viewModel: viewModel)
    }
}
