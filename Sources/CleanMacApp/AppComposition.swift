import CleanMacCore
import CleanMacUI
import DiskMapFeature
import DuplicatesFeature
import LargeFilesFeature
import LoginItemsFeature
import MaintenanceFeature
import MalwareFeature
import MonitorFeature
import PrivacyFeature
import SecurityFeature
import SystemJunkFeature
import UninstallerFeature

/// Composition root: the only place that knows every feature and its concrete dependencies.
@MainActor
enum AppComposition {
    /// What the user chose in the Settings window, kept in the defaults of the app.
    static func makePreferences() -> Preferences {
        Preferences(storage: UserDefaultsPreferenceStorage.standard())
    }

    static func makeModules(preferences: Preferences) -> [any FeatureModule] {
        let uninstaller = UninstallerModule.live()
        let diskMap = DiskMapModule.live(uninstallerFeatureID: uninstaller.id)
        return [
            SystemJunkModule.live(),
            PrivacyModule.live(),
            uninstaller,
            SecurityModule.live(),
            MalwareModule.live(),
            LargeFilesModule.live(preferences: preferences),
            diskMap,
            DuplicatesModule.live(preferences: preferences),
            MaintenanceModule.live(),
            LoginItemsModule.live(),
            MonitorModule.live(preferences: preferences, diskMapFeatureID: diskMap.id)
        ]
    }

    /// Everything in the Settings window: the settings of the app itself, then what each
    /// feature adds, in the order of the features, and last the settings features share,
    /// shown once.
    static func makeSettings(modules: [any FeatureModule], preferences: Preferences) -> SettingsSections {
        let language = SettingsItem(id: AppSettings.language.key, section: .general) {
            LanguagePicker(preferences: preferences)
        }
        // Followed by the large files and the duplicates features, neither of which owns it.
        let excludedFolders = SettingsItem(id: ScanSettings.excludedFolders.key, section: .analysis) {
            ExcludedFolderList(preferences: preferences)
        }
        return SettingsSections(items: [language] + modules.flatMap { $0.settings } + [excludedFolders])
    }

    /// The monitor in the menu bar, which shares the readings of the monitor feature among
    /// `modules`, always one of them, and shows and empties the user's Trash.
    static func makeMenuBarMonitor(modules: [any FeatureModule]) -> MenuBarMonitor {
        guard let monitor = modules.lazy.compactMap({ $0 as? MonitorModule }).first else {
            preconditionFailure("makeModules always includes the monitor, whose readings the menu bar monitor shares.")
        }
        return monitor.makeMenuBarMonitor(trash: .live())
    }

    /// Whether the app goes on running once its last window closes: while the monitor is in
    /// the menu bar, whose menu brings a window back. Quitting would take the menu away too.
    static func keepsRunningWithoutWindows(preferences: Preferences) -> Bool {
        preferences.value(of: MonitorSettings.showsMenuBarExtra)
    }
}
