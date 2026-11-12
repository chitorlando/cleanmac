import Foundation

/// Filters and orders the installed apps shown in the list.
///
/// Ordering compares names as the Finder does, which costs far more than matching the search.
/// The two steps are separate so the list can be ordered once and only filtered as the user types.
public struct AppListQuery: Equatable, Sendable {
    public var searchText: String
    public var sortOrder: AppSortOrder

    public init(searchText: String = "", sortOrder: AppSortOrder = .name) {
        self.searchText = searchText
        self.sortOrder = sortOrder
    }

    /// The apps in the chosen order.
    public func sorted(_ apps: [InstalledApp]) -> [InstalledApp] {
        apps.sorted(by: isOrderedBefore)
    }

    /// The apps that match the search, in the order they come in.
    public func filtered(_ apps: [InstalledApp]) -> [InstalledApp] {
        apps.filter(matchesSearch)
    }

    /// Matches the app name, its alternate names or its bundle ID, ignoring case and accents.
    private func matchesSearch(_ app: InstalledApp) -> Bool {
        let term = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !term.isEmpty else { return true }
        let fields = [app.info.name, app.info.bundleID] + app.info.alternateNames
        return fields.contains { $0.range(of: term, options: [.caseInsensitive, .diacriticInsensitive]) != nil }
    }

    private func isOrderedBefore(_ lhs: InstalledApp, _ rhs: InstalledApp) -> Bool {
        if sortOrder == .size, lhs.totalSize != rhs.totalSize {
            return lhs.totalSize > rhs.totalSize
        }
        switch lhs.info.name.localizedStandardCompare(rhs.info.name) {
        case .orderedAscending: return true
        case .orderedDescending: return false
        case .orderedSame: return lhs.info.url.path < rhs.info.url.path
        }
    }
}
