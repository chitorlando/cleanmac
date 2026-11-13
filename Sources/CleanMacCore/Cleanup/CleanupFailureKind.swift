/// Why an item couldn't be moved to the Trash, in terms the user can act on.
public enum CleanupFailureKind: Hashable, Sendable {
    /// macOS doesn't let CleanMac touch it, such as another app's sandbox container.
    /// Full Disk Access, or moving it by hand in Finder, gets around it.
    case protectedByMacOS
    /// Another app has it open.
    case inUse
    /// It was gone before CleanMac got to it.
    case missing
    case unknown
}
