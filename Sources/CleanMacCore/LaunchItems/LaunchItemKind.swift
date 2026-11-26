/// Whether launchd starts an item in a user's session or for the whole system.
public enum LaunchItemKind: Hashable, Sendable {
    /// Runs in a user's session, usually from login.
    case agent
    /// Runs for the whole system, usually from startup, without a user logged in.
    case daemon
}
