/// How confidently a file belongs to an app. Stronger matches win when several apps claim it.
///
/// Rules rank as: exact bundle ID > group container > app name > bundle ID prefix.
/// Within the same rule, the app with the longer (more specific) bundle ID wins.
public struct MatchStrength: Comparable, Hashable, Sendable {
    public let rule: MatchRule
    public let specificity: Int

    public init(rule: MatchRule, specificity: Int) {
        self.rule = rule
        self.specificity = specificity
    }

    public static func < (lhs: MatchStrength, rhs: MatchStrength) -> Bool {
        (lhs.rank, lhs.specificity) < (rhs.rank, rhs.specificity)
    }

    private var rank: Int {
        switch rule {
        case .bundleIDPrefix: 0
        case .appName: 1
        case .groupContainer: 2
        case .bundleID: 3
        }
    }
}
