import Foundation

extension LeftoverKind {
    var title: String {
        switch self {
        case .applicationSupport:
            String(localized: "Support Files", bundle: .module, comment: "Group of files an app keeps in Application Support.")
        case .caches:
            String(localized: "Caches", bundle: .module, comment: "Group of an app's cache files.")
        case .preferences:
            String(localized: "Preferences", bundle: .module, comment: "Group of an app's preference files.")
        case .containers:
            String(localized: "Containers", bundle: .module, comment: "Group of an app's sandbox containers.")
        case .groupContainers:
            String(localized: "Group Containers", bundle: .module, comment: "Group of containers an app shares with its extensions.")
        case .savedState:
            String(localized: "Saved State", bundle: .module, comment: "Group of files that restore an app's windows.")
        case .logs:
            String(localized: "Logs", bundle: .module, comment: "Group of an app's log files.")
        case .webData:
            String(localized: "Web Data", bundle: .module, comment: "Group of an app's cookies and web storage.")
        case .launchAgents:
            String(localized: "Launch Agents", bundle: .module, comment: "Group of background helpers that start at login.")
        case .scripts:
            String(localized: "App Scripts", bundle: .module, comment: "Group of an app's scripts folder.")
        }
    }
}
