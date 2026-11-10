import CleanMacCore
import CleanMacUI
import Foundation
import SwiftUI

/// Entry point of the disk map feature for the app shell.
@MainActor
public final class DiskMapModule: FeatureModule {
    public let id = "disk-map"
    public let title = String(localized: "Disk Map", bundle: .module, comment: "Feature name in the sidebar.")
    public let symbolName = "chart.pie.fill"
    public let theme = FeatureTheme.neutral
    public let section = FeatureSection.files

    private let viewModel: DiskMapViewModel

    public init(viewModel: DiskMapViewModel) {
        self.viewModel = viewModel
    }

    public func makeView() -> AnyView {
        AnyView(DiskMapView(viewModel: viewModel, theme: theme))
    }
}

public extension DiskMapModule {
    /// Module that maps the current user's whole home folder and moves what the policy allows to the Trash.
    static func live() -> DiskMapModule {
        let viewModel = DiskMapViewModel(
            scanner: DiskMapScanner.home(),
            cleanupService: CleanupService(remover: TrashItemRemover()),
            policy: DiskMapRemovalPolicy()
        )
        return DiskMapModule(viewModel: viewModel)
    }
}
