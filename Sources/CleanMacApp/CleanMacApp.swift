import CleanMacUI
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
    private let modules = AppComposition.makeModules()

    var body: some Scene {
        WindowGroup {
            AppRootView(modules: modules, upcoming: UpcomingFeature.roadmap, permissions: permissions)
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
    }
}
