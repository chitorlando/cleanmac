import Foundation

/// Knows which apps are open and can ask them to quit, such as before removing their files.
@MainActor
public protocol RunningAppsProviding {
    /// Every running app, with the standardized URL of its bundle.
    func runningApps() -> [RunningApp]

    /// Asks every running instance of the app to quit and waits for it.
    /// Returns `true` when none is left running, including when it was not running at all.
    func quit(appAt url: URL) async -> Bool
}
