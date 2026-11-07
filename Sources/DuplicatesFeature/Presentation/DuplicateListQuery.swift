import Foundation

/// Filters and orders the duplicate groups shown in the list.
public struct DuplicateListQuery: Equatable, Sendable {
    public var searchText: String
    public var sortOrder: DuplicateSortOrder

    public init(searchText: String = "", sortOrder: DuplicateSortOrder = .recoverableSize) {
        self.searchText = searchText
        self.sortOrder = sortOrder
    }

    public func apply(to groups: [DuplicateGroup]) -> [DuplicateGroup] {
        groups.filter(matchesSearch).sorted(by: isOrderedBefore)
    }

    /// Matches the path of any copy, ignoring case and accents.
    private func matchesSearch(_ group: DuplicateGroup) -> Bool {
        let term = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !term.isEmpty else { return true }
        return group.files.contains {
            $0.item.url.path.range(of: term, options: [.caseInsensitive, .diacriticInsensitive]) != nil
        }
    }

    private func isOrderedBefore(_ lhs: DuplicateGroup, _ rhs: DuplicateGroup) -> Bool {
        if sortOrder == .recoverableSize, lhs.recoverableSize != rhs.recoverableSize {
            return lhs.recoverableSize > rhs.recoverableSize
        }
        switch lhs.name.localizedStandardCompare(rhs.name) {
        case .orderedAscending: return true
        case .orderedDescending: return false
        case .orderedSame: return lhs.id < rhs.id
        }
    }
}
