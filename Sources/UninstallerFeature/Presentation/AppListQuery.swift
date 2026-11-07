import Foundation

/// Filters and orders the installed apps shown in the list.
public struct AppListQuery: Equatable, Sendable {
    public var searchText: String
    public var sortOrder: AppSortOrder

    public init(searchText: String = "", sortOrder: AppSortOrder = .name) {
        self.searchText = searchText
        self.sortOrder = sortOrder
    }

    public func apply(to apps: [InstalledApp]) -> [InstalledApp] {
        apps.filter(matchesSearch).sorted(by: isOrderedBefore)
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
