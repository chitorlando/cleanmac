/// Outcome of trying to open a file that privacy protection guards.
public enum ProtectedFileAccess: Equatable, Sendable {
    /// It opened, so the protection lets CleanMac in.
    case allowed
    /// The protection refused it.
    case denied
    /// There's no such file, so it says nothing either way.
    case missing
}
