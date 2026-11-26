/// Steps the security screen goes through.
public enum SecurityPhase: Hashable, Sendable {
    case intro
    case reviewing
    case results(SecurityReport)
}

/// How far a review in progress has got.
public struct SecurityReviewProgress: Hashable, Sendable {
    public var step: SecurityReviewStep = .protections
    public var checkedApps = 0
    /// How many apps the review checks, or 0 before it has found them.
    public var appCount = 0

    public init() {}

    /// The share of the apps checked so far, or `nil` while no app is being checked and the
    /// time left can't be told.
    public var fraction: Double? {
        guard step != .protections, appCount > 0 else { return nil }
        return Double(checkedApps) / Double(appCount)
    }
}
