/// Everything one security review found.
public struct SecurityReport: Hashable, Sendable {
    /// One check for each protection of macOS, in the order of `ProtectionKind`.
    public let protections: [ProtectionCheck]
    /// Every app checked, in the order they were found.
    public let apps: [AppSignatureCheck]

    public init(protections: [ProtectionCheck] = [], apps: [AppSignatureCheck] = []) {
        self.protections = protections
        self.apps = apps
    }

    /// The protections that are off, partly off or out of date.
    public var protectionsNeedingAttention: [ProtectionCheck] {
        protections.filter(\.state.needsAttention)
    }

    /// The apps whose signature is missing, broken or not trusted by Gatekeeper.
    public var appsNeedingAttention: [AppSignatureCheck] {
        apps.filter(\.signature.isRisky)
    }

    /// How many findings the user should look at.
    public var attentionCount: Int {
        protectionsNeedingAttention.count + appsNeedingAttention.count
    }
}
