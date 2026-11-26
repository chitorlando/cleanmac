import Foundation

/// Everything one security review found.
public struct SecurityReport: Hashable, Sendable {
    /// One check for each protection of macOS, in the order of `ProtectionKind`.
    public let protections: [ProtectionCheck]
    /// Every app checked, in the order they were found.
    public let apps: [AppSignatureCheck]
    /// The login and background items that deserve a look.
    public let persistence: [PersistenceFinding]
    /// Which apps have each sensitive permission.
    public let permissions: PermissionsReview

    public init(
        protections: [ProtectionCheck] = [],
        apps: [AppSignatureCheck] = [],
        persistence: [PersistenceFinding] = [],
        permissions: PermissionsReview = PermissionsReview(availability: .complete)
    ) {
        self.protections = protections
        self.apps = apps
        self.persistence = persistence
        self.permissions = permissions
    }

    /// The protections that are off, partly off or out of date.
    public var protectionsNeedingAttention: [ProtectionCheck] {
        protections.filter(\.state.needsAttention)
    }

    /// The apps whose signature is missing, broken or not trusted by Gatekeeper.
    public var appsNeedingAttention: [AppSignatureCheck] {
        apps.filter(\.signature.isRisky)
    }

    /// The apps with a sensitive permission whose signature is missing or damaged, leaving out
    /// those already among `appsNeedingAttention`.
    public var permissionClientsNeedingAttention: [PermissionClient] {
        let flaggedApps = Set(appsNeedingAttention.map(\.url.standardizedFileURL.path))
        return permissions.clientsNeedingAttention.filter { client in
            client.url.map { !flaggedApps.contains($0.standardizedFileURL.path) } ?? true
        }
    }

    /// How many findings the user should look at, each once.
    public var attentionCount: Int {
        protectionsNeedingAttention.count + appsNeedingAttention.count + persistence.count
            + permissionClientsNeedingAttention.count
    }
}
