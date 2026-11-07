/// How the list of installed apps is ordered.
public enum AppSortOrder: String, CaseIterable, Hashable, Sendable {
    /// Alphabetically, as the Finder sorts names.
    case name
    /// Largest total size first.
    case size
}
