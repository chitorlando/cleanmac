/// A permission of Privacy & Security that lets an app see or control much more than usual.
public enum PrivacyPermission: CaseIterable, Hashable, Sendable {
    case fullDiskAccess
    case screenRecording
    case accessibility
    case inputMonitoring
    case camera
    case microphone

    /// The permission's name in the privacy database, the `service` column of its `access` table.
    public var service: String {
        switch self {
        case .fullDiskAccess: "kTCCServiceSystemPolicyAllFiles"
        case .screenRecording: "kTCCServiceScreenCapture"
        case .accessibility: "kTCCServiceAccessibility"
        case .inputMonitoring: "kTCCServiceListenEvent"
        case .camera: "kTCCServiceCamera"
        case .microphone: "kTCCServiceMicrophone"
        }
    }

    /// The permission a privacy database service names, or `nil` for one the review leaves out.
    public init?(service: String) {
        guard let permission = Self.allCases.first(where: { $0.service == service }) else { return nil }
        self = permission
    }
}

/// An app or program allowed a permission, as the privacy database names it.
public struct PermissionGrant: Hashable, Sendable {
    /// How the privacy database names who was allowed.
    public enum Client: Hashable, Sendable {
        /// An app, by its bundle identifier.
        case bundleID(String)
        /// A program, by its absolute path.
        case path(String)
    }

    public let permission: PrivacyPermission
    public let client: Client

    public init(permission: PrivacyPermission, client: Client) {
        self.permission = permission
        self.client = client
    }
}
