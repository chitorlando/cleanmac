import Foundation

/// Every folder of the user's Library where apps leave files behind.
/// System-wide folders (`/Library`, `/System`) are deliberately left out.
public enum LeftoverCatalog {
    public static func userLocations(home: URL) -> [LeftoverLocation] {
        let library = home.appending(path: "Library")
        let identified: [MatchRule] = [.bundleID, .bundleIDPrefix]
        let named: [MatchRule] = [.bundleID, .bundleIDPrefix, .appName]

        func location(_ path: String, _ kind: LeftoverKind, _ rules: [MatchRule]) -> LeftoverLocation {
            LeftoverLocation(url: library.appending(path: path), kind: kind, rules: rules)
        }

        return [
            location("Application Support", .applicationSupport, named),
            location("Caches", .caches, named),
            location("Preferences", .preferences, identified),
            location("Preferences/ByHost", .preferences, identified),
            location("Containers", .containers, identified),
            location("Group Containers", .groupContainers, [.groupContainer]),
            location("Saved Application State", .savedState, [.bundleID]),
            location("Logs", .logs, named),
            location("HTTPStorages", .webData, identified),
            location("WebKit", .webData, identified),
            location("Cookies", .webData, [.bundleID]),
            location("LaunchAgents", .launchAgents, identified),
            location("Application Scripts", .scripts, identified)
        ]
    }
}
