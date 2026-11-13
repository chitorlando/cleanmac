/// Whether the user gave CleanMac a privacy permission.
public enum PermissionStatus: Equatable, Sendable {
    case granted
    case denied
    /// The user hasn't been asked yet.
    case notDetermined
}
