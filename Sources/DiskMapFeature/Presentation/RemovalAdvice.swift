/// What the disk map lets the user do with an item, besides showing it in Finder.
public enum RemovalAdvice: Equatable, Sendable {
    /// It can be moved to the Trash.
    case allowed
    /// The home folder or one of its standard folders, such as Documents.
    /// What's inside can go, but not the folder itself.
    case standardFolder
    /// Data that apps keep in `~/Library`. Removing it could break them, so it's only shown.
    case appData
    /// Data that must never be removed from here: keychains, mail, messages,
    /// iCloud Drive, cloud storage, app containers and photo libraries.
    case protectedData
    /// An app, which the Uninstaller removes together with the files it leaves behind.
    case useUninstaller

    public var allowsMovingToTrash: Bool { self == .allowed }
}
