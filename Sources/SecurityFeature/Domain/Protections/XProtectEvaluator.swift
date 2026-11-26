import Foundation

/// A copy of XProtect's definitions found on disk.
public struct XProtectBundle: Hashable, Sendable {
    /// `CFBundleShortVersionString`, such as “5377”.
    public let version: String?
    /// When its Info.plist last changed, which an update of the definitions does.
    public let updatedAt: Date

    public init(version: String?, updatedAt: Date) {
        self.version = version
        self.updatedAt = updatedAt
    }
}

/// Tells whether XProtect's definitions still get updated.
public enum XProtectEvaluator {
    /// Apple updates the definitions every few weeks. Older than this, they've stopped coming,
    /// usually because automatic updates of system data files are off.
    public static let maximumAge: TimeInterval = 90 * 24 * 60 * 60

    /// - Parameter bundles: Every copy found. macOS keeps more than one on some versions,
    ///   and the newest is the one in use.
    public static func check(bundles: [XProtectBundle], now: Date) -> ProtectionCheck {
        guard let newest = bundles.max(by: { $0.updatedAt < $1.updatedAt }) else {
            return ProtectionCheck(kind: .xprotect, state: .unknown)
        }
        let isOutdated = now.timeIntervalSince(newest.updatedAt) > maximumAge
        return ProtectionCheck(
            kind: .xprotect,
            state: isOutdated ? .outdated : .on,
            detail: .xprotect(version: newest.version, updatedAt: newest.updatedAt)
        )
    }
}
