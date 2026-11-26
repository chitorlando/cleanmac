import AppKit

/// Makes the app behave like a regular windowed app, also when launched with `swift run`.
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activateAtUserRequest()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        !AppComposition.keepsRunningWithoutWindows(preferences: AppComposition.makePreferences())
    }
}
