import AppKit
import CleanMacUI
import Foundation
import SwiftUI

/// Entry point of the monitor feature for the app shell.
@MainActor
public final class MonitorModule: FeatureModule {
    public let id = "monitor"
    public let title = String(localized: "Monitor", bundle: .module, comment: "Feature name in the sidebar.")
    public let symbolName = MonitorModule.gaugeSymbolName
    public let theme = FeatureTheme.monitor
    public let section = FeatureSection.performance

    private let viewModel: MonitorViewModel
    private let diskMapFeatureID: String?

    /// - Parameter diskMapFeatureID: Id of the disk map feature, which the disk card opens.
    ///   Without it, the card has no button.
    public init(viewModel: MonitorViewModel, diskMapFeatureID: String? = nil) {
        self.viewModel = viewModel
        self.diskMapFeatureID = diskMapFeatureID
    }

    public func makeView() -> AnyView {
        AnyView(MonitorView(viewModel: viewModel, theme: theme, diskMapFeatureID: diskMapFeatureID))
    }

    /// The gauge of the monitor. SF Symbols 5 gave it a new name, and macOS 13 only knows
    /// the old one, so the new name would draw nothing there.
    static var gaugeSymbolName: String {
        if #available(macOS 14, *) {
            return "gauge.with.dots.needle.67percent"
        } else {
            return "speedometer"
        }
    }
}

public extension MonitorModule {
    /// Module that reads this Mac, only while some part of the app can be seen.
    ///
    /// - Parameter diskMapFeatureID: See `init(viewModel:diskMapFeatureID:)`.
    static func live(diskMapFeatureID: String? = nil) -> MonitorModule {
        let viewModel = MonitorViewModel(
            sampler: SystemSampler.live(),
            isVisible: { NSApplication.shared.occlusionState.contains(.visible) }
        )
        return MonitorModule(viewModel: viewModel, diskMapFeatureID: diskMapFeatureID)
    }
}
