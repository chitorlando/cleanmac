import CleanMacCore
import CleanMacUI
import DiskMapFeature
import DuplicatesFeature
import LargeFilesFeature
import LoginItemsFeature
import MaintenanceFeature
import MonitorFeature
import PrivacyFeature
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
            LargeFilesModule.live(),
            diskMap,
            DuplicatesModule.live(),
            MaintenanceModule.live(),
            LoginItemsModule.live(),
            MonitorModule.live(preferences: preferences, diskMapFeatureID: diskMap.id)
        ]
    }

    /// Everything in the Settings window: the settings of the app itself, then what each
    /// feature adds, in the order of the features.
    static func makeSettings(modules: [any FeatureModule], preferences: Preferences) -> SettingsSections {
        let language = SettingsItem(id: AppSettings.language.key, section: .general) {
            LanguagePicker(preferences: preferences)
        }
        return SettingsSections(items: [language] + modules.flatMap { $0.settings })
    }
}
