import Foundation

/// How the list of large files is ordered.
public enum LargeFileSortOrder: String, CaseIterable, Hashable, Sendable {
    /// Largest first.
    case size
    /// Alphabetically, as the Finder sorts names.
    case name
    /// Least recently used first. Files with no known date go last.
    case lastAccess

    public func sorted(_ files: [LargeFile]) -> [LargeFile] {
        files.sorted(by: isOrderedBefore)
    }

    private func isOrderedBefore(_ lhs: LargeFile, _ rhs: LargeFile) -> Bool {
        switch self {
        case .size where lhs.item.size != rhs.item.size:
            return lhs.item.size > rhs.item.size
        case .lastAccess where lhs.lastAccessDate != rhs.lastAccessDate:
            return Self.isOlder(lhs.lastAccessDate, than: rhs.lastAccessDate)
        default:
            return Self.isAlphabeticallyBefore(lhs, rhs)
        }
    }

    private static func isOlder(_ lhs: Date?, than rhs: Date?) -> Bool {
        switch (lhs, rhs) {
        case let (lhs?, rhs?): lhs < rhs
        case (.some, .none): true
        default: false
        }
    }

    /// By name, then by path so files with the same name keep a stable order.
    private static func isAlphabeticallyBefore(_ lhs: LargeFile, _ rhs: LargeFile) -> Bool {
        switch lhs.name.localizedStandardCompare(rhs.name) {
        case .orderedAscending: true
        case .orderedDescending: false
        case .orderedSame: lhs.item.url.path < rhs.item.url.path
        }
    }
}
