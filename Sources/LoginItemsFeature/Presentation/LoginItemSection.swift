/// The items of one scope, as the list groups them.
public struct LoginItemSection: Identifiable, Equatable, Sendable {
    public let scope: LaunchScope
    /// Orphaned items first, since they're leftovers of deleted apps, then by name.
    public let items: [LoginItem]

    public var id: LaunchScope { scope }

    public init(scope: LaunchScope, items: [LoginItem]) {
        self.scope = scope
        self.items = items.sorted(by: Self.isOrderedBefore)
    }

    /// One section per scope that has items, the user's own first.
    public static func sections(of items: [LoginItem]) -> [LoginItemSection] {
        LaunchScope.allCases.compactMap { scope in
            let scoped = items.filter { $0.scope == scope }
            return scoped.isEmpty ? nil : LoginItemSection(scope: scope, items: scoped)
        }
    }

    private static func isOrderedBefore(_ lhs: LoginItem, _ rhs: LoginItem) -> Bool {
        if lhs.isOrphaned != rhs.isOrphaned {
            return lhs.isOrphaned
        }
        switch lhs.displayName.localizedStandardCompare(rhs.displayName) {
        case .orderedAscending: return true
        case .orderedDescending: return false
        case .orderedSame: return lhs.plistURL.path < rhs.plistURL.path
        }
    }
}
