import Foundation

/// Knows which apps are open and can ask them to quit before they are uninstalled.
@MainActor
public protocol RunningAppsProviding {
    /// Standardized bundle URLs of every running app.
    func runningAppURLs() -> Set<URL>

    /// Asks every running instance of the app to quit and waits for it.
    /// Returns `true` when none is left running, including when it was not running at all.
    func quit(appAt url: URL) async -> Bool
}
