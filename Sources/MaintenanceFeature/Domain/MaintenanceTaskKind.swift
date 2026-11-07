import Foundation

/// A maintenance routine and the commands that perform it.
public enum MaintenanceTaskKind: String, CaseIterable, Identifiable, Sendable {
    case flushDNS
    case freeMemory
    case reindexSpotlight
    case rebuildLaunchServices
    case resetQuickLook

    private static let launchServicesRegister =
        "/System/Library/Frameworks/CoreServices.framework/Frameworks/"
        + "LaunchServices.framework/Support/lsregister"

    public var id: String { rawValue }

    public var privilege: MaintenancePrivilege {
        switch self {
        case .flushDNS, .freeMemory, .reindexSpotlight: .administrator
        case .rebuildLaunchServices, .resetQuickLook: .user
        }
    }

    /// Commands to run in order; the task fails at the first one that fails.
    public var commands: [ShellCommand] {
        switch self {
        case .flushDNS:
            [
                ShellCommand("/usr/bin/dscacheutil", "-flushcache"),
                ShellCommand("/usr/bin/killall", "-HUP", "mDNSResponder")
            ]
        case .freeMemory:
            [ShellCommand("/usr/sbin/purge")]
        case .reindexSpotlight:
            [ShellCommand("/usr/bin/mdutil", "-E", "/")]
        case .rebuildLaunchServices:
            // Drops stale records, then re-registers every app in the local, system and user domains.
            [ShellCommand(Self.launchServicesRegister, "-gc", "-r", "-f", "-all", "local,system,user")]
        case .resetQuickLook:
            [ShellCommand("/usr/bin/qlmanage", "-r", "cache")]
        }
    }
}
