import AppKit
import CleanMacCore
import CleanMacUI
import Combine
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
    private let preferences: Preferences
    private let diskMapFeatureID: String?
    private var refreshIntervalChanges: AnyCancellable?

    /// - Parameters:
    ///   - preferences: Where the user chooses the time between readings, which `viewModel`
    ///     follows from now on.
    ///   - diskMapFeatureID: Id of the disk map feature, which the disk card opens.
    ///     Without it, the card has no button.
    public init(viewModel: MonitorViewModel, preferences: Preferences, diskMapFeatureID: String? = nil) {
        self.viewModel = viewModel
        self.preferences = preferences
        self.diskMapFeatureID = diskMapFeatureID
        viewModel.interval = .seconds(preferences.value(of: MonitorSettings.refreshInterval))
        refreshIntervalChanges = preferences.changes(of: MonitorSettings.refreshInterval)
            .sink { [viewModel] seconds in viewModel.interval = .seconds(seconds) }
    }

    /// The monitor in the menu bar, which shares the readings of the monitor's screens.
    public private(set) lazy var menuBarMonitor = MenuBarMonitor(monitor: viewModel, preferences: preferences, featureID: id)

    public func makeView() -> AnyView {
        AnyView(MonitorView(viewModel: viewModel, theme: theme, diskMapFeatureID: diskMapFeatureID))
    }

    /// Whether the monitor is in the menu bar goes with the settings of the whole app, since
    /// it also keeps the app running without windows.
    public var settings: [SettingsItem] {
        [
            SettingsItem(id: MonitorSettings.showsMenuBarExtra.key, section: .general) { [preferences] in
                MenuBarSettings(preferences: preferences)
            },
            SettingsItem(id: MonitorSettings.refreshInterval.key, section: .monitor) { [preferences] in
                RefreshIntervalPicker(preferences: preferences)
            }
        ]
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
    /// - Parameters:
    ///   - preferences: See `init(viewModel:preferences:diskMapFeatureID:)`.
    ///   - diskMapFeatureID: See `init(viewModel:preferences:diskMapFeatureID:)`.
    static func live(preferences: Preferences, diskMapFeatureID: String? = nil) -> MonitorModule {
        let viewModel = MonitorViewModel(
            sampler: SystemSampler.live(),
            isVisible: { NSApplication.shared.occlusionState.contains(.visible) }
        )
        return MonitorModule(viewModel: viewModel, preferences: preferences, diskMapFeatureID: diskMapFeatureID)
    }
}
