import Foundation

/// Names of items that must never be offered for removal.
public struct ExclusionRules: Sendable {
    private let protectedNames: Set<String>

    public init(protectedNames: Set<String>) {
        self.protectedNames = protectedNames
    }

    public func excludes(_ url: URL) -> Bool {
        protectedNames.contains(url.lastPathComponent)
    }
}

public extension ExclusionRules {
    /// Caches that hold sync state or credentials. Removing them can force iCloud
    /// to resync or sign the user out, so they are always kept.
    static let standard = ExclusionRules(protectedNames: [
        "com.apple.bird",
        "com.apple.akd",
        "com.apple.ap.adprivacyd",
        "CloudKit",
        "FamilyCircle",
        AppIdentity.bundleIdentifier
    ])
}
