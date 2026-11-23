/// How a browser keeps its profiles inside its user data folder.
public enum ProfileLayout: Hashable, Sendable {
    /// Chromium: one folder per profile, named "Default" or "Profile" followed by a number.
    case chromium
    /// Every folder is a profile, as Firefox names them with a random prefix.
    case anyFolder
    /// The user data folder is the only profile, as in Opera.
    case rootIsProfile
}
