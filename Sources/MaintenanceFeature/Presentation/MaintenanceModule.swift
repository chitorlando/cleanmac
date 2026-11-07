import CleanMacUI
import Foundation
import SwiftUI

/// Entry point of the maintenance feature for the app shell.
@MainActor
public final class MaintenanceModule: FeatureModule {
    public let id = "maintenance"
    public let title = String(localized: "Maintenance", bundle: .module, comment: "Feature name in the sidebar.")
    public let symbolName = "wrench.and.screwdriver.fill"
    public let theme = FeatureTheme.maintenance
    public let section = FeatureSection.performance

    private let viewModel: MaintenanceViewModel

    public init(viewModel: MaintenanceViewModel) {
        self.viewModel = viewModel
    }

    public func makeView() -> AnyView {
        AnyView(MaintenanceView(viewModel: viewModel, theme: theme))
    }
}

public extension MaintenanceModule {
    /// Module wired to the real system tools of this Mac.
    static func live() -> MaintenanceModule {
        MaintenanceModule(viewModel: MaintenanceViewModel(runner: MaintenanceService()))
    }
}
