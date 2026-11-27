import CleanMacUI
import Combine
import MonitorFeature
import OnboardingFeature
import SwiftUI

@main
struct CleanMacApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var updater = AppUpdater()
    @StateObject private var permissions: PermissionsViewModel = {
        let permissions = PermissionsViewModel.live()
        permissions.prepareForLaunch()
        return permissions
    }()
    @StateObject private var menuBarMonitor: MenuBarMonitor
    private let modules: [any FeatureModule]
    private let settings: SettingsSections
    private let mainWindows = MainWindows()
    /// Plays the sound effects of the features and of the menu bar while the app runs.
    private let soundEffectPlayback: AnyCancellable

    init() {
        let preferences = AppComposition.makePreferences()
        let modules = AppComposition.makeModules(preferences: preferences)
        let menuBarMonitor = AppComposition.makeMenuBarMonitor(modules: modules)
        self.modules = modules
        settings = AppComposition.makeSettings(modules: modules, preferences: preferences)
        _menuBarMonitor = StateObject(wrappedValue: menuBarMonitor)
        soundEffectPlayback = AppComposition.playSoundEffects(of: modules, menuBarMonitor: menuBarMonitor, preferences: preferences)
    }

    var body: some Scene {
        WindowGroup(id: MainWindows.sceneID) {
            AppRootView(modules: modules, upcoming: UpcomingFeature.roadmap, permissions: permissions, mainWindows: mainWindows)
                .frame(minWidth: 900, minHeight: 600)
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 1080, height: 700)
        .commands {
            CommandGroup(after: .appInfo) {
                CheckForUpdatesButton(updater: updater)
                PermissionsMenuButton(permissions: permissions)
            }
        }

        Settings {
            SettingsView(sections: settings)
        }

        // Taking the icon out of the menu bar with the Command key held turns the setting off.
        MenuBarExtra(isInserted: $menuBarMonitor.isShown) {
            MenuBarMonitorContent(menuBarMonitor: menuBarMonitor, mainWindows: mainWindows)
        } label: {
            menuBarMonitor.makeLabel()
        }
        .menuBarExtraStyle(.window)
    }
}
