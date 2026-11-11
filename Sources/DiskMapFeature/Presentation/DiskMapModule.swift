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
    public let theme = FeatureTheme.diskMap
    public let section = FeatureSection.files

    private let viewModel: DiskMapViewModel
    private let uninstallerFeatureID: String?

    /// - Parameter uninstallerFeatureID: Id of the feature that uninstalls apps, which the map
    ///   opens for the apps it won't remove itself. Without it, the map only names that feature.
    public init(viewModel: DiskMapViewModel, uninstallerFeatureID: String? = nil) {
        self.viewModel = viewModel
        self.uninstallerFeatureID = uninstallerFeatureID
    }

    public func makeView() -> AnyView {
        AnyView(
            DiskMapView(viewModel: viewModel, theme: theme)
                .environment(\.uninstallerFeatureID, uninstallerFeatureID)
        )
    }
}

public extension DiskMapModule {
    /// Module that maps the current user's whole home folder and moves what the policy allows to the Trash.
    ///
    /// - Parameter uninstallerFeatureID: See `init(viewModel:uninstallerFeatureID:)`.
    static func live(uninstallerFeatureID: String? = nil) -> DiskMapModule {
        let viewModel = DiskMapViewModel(
            scanner: DiskMapScanner.home(),
            cleanupService: CleanupService(remover: TrashItemRemover()),
            policy: DiskMapRemovalPolicy()
        )
        return DiskMapModule(viewModel: viewModel, uninstallerFeatureID: uninstallerFeatureID)
    }
}
