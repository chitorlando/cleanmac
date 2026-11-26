import Foundation

/// Which apps have each sensitive permission. Informational: an app is only flagged when its
/// signature is missing or damaged.
public struct PermissionsReview: Hashable, Sendable {
    /// How much of the privacy databases could be read.
    public enum Availability: Hashable, Sendable {
        /// Every database was read.
        case complete
        /// Some database couldn't be read, so some apps may be missing.
        case partial
        /// No database could be read, which is what happens without Full Disk Access.
        case unavailable
    }

    public let availability: Availability
    /// One group for each permission allowed to any app, in the order of `PrivacyPermission`.
    public let groups: [PermissionGroup]

    public init(availability: Availability, groups: [PermissionGroup] = []) {
        self.availability = availability
        self.groups = groups
    }

    /// The apps allowed a sensitive permission whose signature is missing or damaged, once each.
    public var clientsNeedingAttention: [PermissionClient] {
        var seen: Set<String> = []
        return groups.flatMap(\.clients).filter { $0.isRisky && seen.insert($0.id).inserted }
    }
}

/// The apps allowed one permission.
public struct PermissionGroup: Identifiable, Hashable, Sendable {
    public let permission: PrivacyPermission
    /// Sorted by name.
    public let clients: [PermissionClient]

    public init(permission: PrivacyPermission, clients: [PermissionClient]) {
        self.permission = permission
        self.clients = clients
    }

    public var id: PrivacyPermission { permission }
}

/// An app or program allowed a permission, found on disk when possible.
public struct PermissionClient: Identifiable, Hashable, Sendable {
    /// The bundle identifier or path the privacy database names it by.
    public let identifier: String
    public let name: String
    /// The app, or the program when it isn't in an app. `nil` when it isn't on this Mac anymore.
    public let url: URL?
    /// How it's signed, when it was found.
    public let signature: AppSignature?

    public init(identifier: String, name: String, url: URL?, signature: AppSignature?) {
        self.identifier = identifier
        self.name = name
        self.url = url
        self.signature = signature
    }

    public var id: String { identifier }

    /// Only a missing or damaged signature is worth a warning here.
    public var isRisky: Bool {
        signature == .unsigned || signature == .damaged
    }
}
