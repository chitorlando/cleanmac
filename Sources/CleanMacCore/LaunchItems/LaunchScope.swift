/// Who a launchd item runs for, which decides who can remove it.
public enum LaunchScope: CaseIterable, Hashable, Sendable {
    /// Agents in the user's own Library. The user can remove them.
    case currentUser
    /// Agents and daemons in `/Library`, shared by every user. Removing them needs an administrator.
    case allUsers
}
