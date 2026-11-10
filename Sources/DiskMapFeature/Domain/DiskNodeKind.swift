/// What an item of the disk map is.
public enum DiskNodeKind: Hashable, Sendable {
    case folder
    case file
    /// An app, photo library or other package, measured whole and never entered.
    case package
}
