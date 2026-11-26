import Foundation

/// What the review found about one protection.
public struct ProtectionCheck: Identifiable, Hashable, Sendable {
    public let kind: ProtectionKind
    public let state: ProtectionState
    public let detail: ProtectionDetail?

    public init(kind: ProtectionKind, state: ProtectionState, detail: ProtectionDetail? = nil) {
        self.kind = kind
        self.state = state
        self.detail = detail
    }

    public var id: ProtectionKind { kind }
}

/// Facts that explain the state of a protection.
public enum ProtectionDetail: Hashable, Sendable {
    /// The automatic update options that are off, in the order Software Update lists them.
    case updateOptionsOff([AutomaticUpdateOption])
    /// XProtect's version, when it has one, and when its definitions last changed.
    case xprotect(version: String?, updatedAt: Date)
}
