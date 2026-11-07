import Foundation

/// A Library folder whose direct children may belong to apps, and how to recognize them.
public struct LeftoverLocation: Hashable, Sendable {
    public let url: URL
    public let kind: LeftoverKind
    public let rules: [MatchRule]

    public init(url: URL, kind: LeftoverKind, rules: [MatchRule]) {
        self.url = url
        self.kind = kind
        self.rules = rules
    }
}
