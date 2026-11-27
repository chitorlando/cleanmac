import CleanMacCore
import CleanMacUI
import Combine
import DiskMapFeature
import DuplicatesFeature
import LargeFilesFeature
import LoginItemsFeature
import MaintenanceFeature
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
        let soundEffects = SettingsItem(id: SoundEffectSettings.isEnabled.key, section: .general) {
            SoundEffectsToggle(preferences: preferences)
        }
        // Followed by the large files and the duplicates features, neither of which owns it.
        let excludedFolders = SettingsItem(id: ScanSettings.excludedFolders.key, section: .analysis) {
            ExcludedFolderList(preferences: preferences)
        }
        return SettingsSections(items: [language, soundEffects] + modules.flatMap { $0.settings } + [excludedFolders])
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

    /// Plays the sound effects of `modules` and of `menuBarMonitor` as they happen, with the
    /// sounds of macOS, for as long as the result is kept. They're quiet while the user turned
    /// them off in the Settings window, or macOS plays no sound effects of its own interface.
    static func playSoundEffects(
        of modules: [any FeatureModule],
        menuBarMonitor: MenuBarMonitor,
        preferences: Preferences
    ) -> AnyCancellable {
        let player = GatedSoundEffectPlayer(
            player: SystemSoundEffectPlayer(),
            preferences: preferences,
            userInterfaceSounds: UserInterfaceSoundsPreference()
        )
        return playSoundEffects(modules.map { $0.soundEffects } + [menuBarMonitor.soundEffects], through: player)
    }

    /// Plays through `player` each sound effect that `soundEffects` send, for as long as the
    /// result is kept.
    static func playSoundEffects(
        _ soundEffects: [AnyPublisher<SoundEffect, Never>],
        through player: any SoundEffectPlaying
    ) -> AnyCancellable {
        Publishers.MergeMany(soundEffects).sink { player.play($0) }
    }
}
