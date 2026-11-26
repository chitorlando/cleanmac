/// Everything one security review found.
public struct SecurityReport: Hashable, Sendable {
    /// One check for each protection of macOS, in the order of `ProtectionKind`.
    public let protections: [ProtectionCheck]

    public init(protections: [ProtectionCheck] = []) {
        self.protections = protections
    }

    /// The protections that are off, partly off or out of date.
    public var protectionsNeedingAttention: [ProtectionCheck] {
        protections.filter(\.state.needsAttention)
    }

    /// How many findings the user should look at.
    public var attentionCount: Int {
        protectionsNeedingAttention.count
    }
}
