/// How a protection is set on this Mac.
public enum ProtectionState: Hashable, Sendable {
    case on
    case off
    /// Some of its parts are off, such as System Integrity Protection in a custom configuration.
    case partial
    /// On, but what it relies on hasn't been updated for a long time.
    case outdated
    /// The review couldn't tell, such as when a tool printed something it doesn't know.
    case unknown

    /// Whether the user should look at it. Unknown states are shown without a warning.
    public var needsAttention: Bool {
        switch self {
        case .off, .partial, .outdated: true
        case .on, .unknown: false
        }
    }
}
