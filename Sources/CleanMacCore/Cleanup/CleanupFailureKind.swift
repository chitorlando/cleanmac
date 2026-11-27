/// Why an item couldn't be moved to the Trash, in terms the user can act on.
public enum CleanupFailureKind: Hashable, Sendable {
    /// macOS doesn't let CleanMac touch it, such as another app's sandbox container.
    /// Full Disk Access, or moving it by hand in Finder, gets around it.
    case protectedByMacOS
    /// CleanMac isn't allowed to control Finder, which it asks to move protected apps to the
    /// Trash and to empty the Trash. Allowing it in the Automation settings gets around it.
    case finderAutomationDenied
    /// Another app has it open.
    case inUse
    /// It was gone before CleanMac got to it.
    case missing
    case unknown
}
