import CleanMacUI
import SwiftUI

@main
struct CleanMacApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var updater = AppUpdater()
    private let modules = AppComposition.makeModules()

    var body: some Scene {
        WindowGroup {
            RootView(modules: modules, upcoming: UpcomingFeature.roadmap)
                .frame(minWidth: 900, minHeight: 600)
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 1080, height: 700)
        .commands {
            CommandGroup(after: .appInfo) {
                CheckForUpdatesButton(updater: updater)
            }
        }
    }
}
