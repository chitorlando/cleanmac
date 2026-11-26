/// Whether something is on disk, as far as it can be told.
public enum ItemPresence: Equatable, Sendable {
    case present
    /// Known to be gone: the file system says there is nothing at that path.
    case missing
    /// It can't be told, as when a folder on the way can't be entered.
    case unknown
}
