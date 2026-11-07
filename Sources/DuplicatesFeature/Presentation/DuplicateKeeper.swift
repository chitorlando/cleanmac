import Foundation

/// Chooses the copy to keep when duplicates are selected automatically.
///
/// It keeps a copy whose removal would free the least space, normally any copy, but a clone
/// of a file outside the group before a copy with its own data. Among those, it keeps the
/// oldest by creation date and, on a tie, the one with the shortest path.
public enum DuplicateKeeper {
    public static func keeper(in group: DuplicateGroup) -> DuplicateFile? {
        guard let leastFreeable = group.physicalCopies.map(\.freeableSize).min() else { return nil }
        return group.physicalCopies
            .filter { $0.freeableSize == leastFreeable }
            .flatMap(\.files)
            .min(by: isPreferred)
    }

    private static func isPreferred(_ lhs: DuplicateFile, _ rhs: DuplicateFile) -> Bool {
        switch (lhs.creationDate, rhs.creationDate) {
        case let (lhsDate?, rhsDate?) where lhsDate != rhsDate:
            return lhsDate < rhsDate
        case (.some, .none):
            return true
        case (.none, .some):
            return false
        default:
            return isShorterPath(lhs.item.url.path, rhs.item.url.path)
        }
    }

    /// Shorter first; equal lengths are ordered alphabetically so the choice is stable.
    private static func isShorterPath(_ lhs: String, _ rhs: String) -> Bool {
        lhs.count != rhs.count ? lhs.count < rhs.count : lhs < rhs
    }
}
