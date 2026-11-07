import Foundation

/// How each maintenance task is shown to the user.
extension MaintenanceTaskKind {
    var title: String {
        switch self {
        case .flushDNS:
            String(localized: "Flush DNS Cache", bundle: .module, comment: "Maintenance task title.")
        case .freeMemory:
            String(localized: "Free Up Memory", bundle: .module, comment: "Maintenance task title.")
        case .reindexSpotlight:
            String(localized: "Reindex Spotlight", bundle: .module, comment: "Maintenance task title.")
        case .rebuildLaunchServices:
            String(localized: "Rebuild Launch Services", bundle: .module, comment: "Maintenance task title.")
        case .resetQuickLook:
            String(localized: "Reset Quick Look", bundle: .module, comment: "Maintenance task title.")
        }
    }

    /// What the task fixes and what to expect while it works.
    var summary: String {
        switch self {
        case .flushDNS:
            String(
                localized: "Clears saved website addresses. Helps when sites fail to load or show an old version.",
                bundle: .module,
                comment: "Description of the Flush DNS Cache maintenance task."
            )
        case .freeMemory:
            String(
                localized: "Releases memory that apps no longer use. Apps may feel slower for a moment while they reload what they need.",
                bundle: .module,
                comment: "Description of the Free Up Memory maintenance task."
            )
        case .reindexSpotlight:
            String(
                localized: "Rebuilds the search index when Spotlight misses files. It can take hours, and searches may be incomplete until it finishes.",
                bundle: .module,
                comment: "Description of the Reindex Spotlight maintenance task."
            )
        case .rebuildLaunchServices:
            String(
                localized: "Refreshes the list of installed apps. Fixes duplicates in “Open With” and files that open in the wrong app.",
                bundle: .module,
                comment: "Description of the Rebuild Launch Services maintenance task. “Open With” is the Finder menu."
            )
        case .resetQuickLook:
            String(
                localized: "Clears the thumbnail cache. Fixes previews and icons that look outdated or broken.",
                bundle: .module,
                comment: "Description of the Reset Quick Look maintenance task."
            )
        }
    }

    /// Shown in the results when the task succeeds.
    var completionNote: String {
        switch self {
        case .flushDNS:
            String(localized: "DNS cache cleared.", bundle: .module, comment: "Result of a successful maintenance task.")
        case .freeMemory:
            String(localized: "Unused memory released.", bundle: .module, comment: "Result of a successful maintenance task.")
        case .reindexSpotlight:
            String(
                localized: "Spotlight is rebuilding its index in the background. Searches may be incomplete for a while.",
                bundle: .module,
                comment: "Result of a successful Spotlight reindex, which keeps working after CleanMac finishes."
            )
        case .rebuildLaunchServices:
            String(localized: "App list refreshed.", bundle: .module, comment: "Result of a successful maintenance task.")
        case .resetQuickLook:
            String(localized: "Thumbnail cache cleared.", bundle: .module, comment: "Result of a successful maintenance task.")
        }
    }

    var symbolName: String {
        switch self {
        case .flushDNS: "network"
        case .freeMemory: "memorychip"
        case .reindexSpotlight: "magnifyingglass"
        case .rebuildLaunchServices: "square.grid.3x3.square"
        case .resetQuickLook: "eye"
        }
    }
}
