/// How the list of duplicate groups is ordered.
public enum DuplicateSortOrder: String, CaseIterable, Hashable, Sendable {
    /// Most space recoverable first.
    case recoverableSize
    /// Alphabetically by file name, as the Finder sorts names.
    case name
}
