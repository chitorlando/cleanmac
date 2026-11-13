import AppKit
import CoreServices

/// `FinderAutomationAuthorizing` through the system's Apple Events permission check.
///
/// Finder is always running, so the check normally answers; anything else counts as not
/// determined, so the user can still be offered the button that asks.
public struct FinderAutomationAuthorizer: FinderAutomationAuthorizing {
    private static let finderBundleID = "com.apple.finder"

    public init() {}

    public func status() -> PermissionStatus {
        Self.determine(askingUser: false)
    }

    /// The system shows its dialog and waits for the answer, so this runs off the main thread.
    public func requestAccess() async -> PermissionStatus {
        await Task.detached(priority: .userInitiated) {
            Self.determine(askingUser: true)
        }.value
    }

    private static func determine(askingUser: Bool) -> PermissionStatus {
        let finder = NSAppleEventDescriptor(bundleIdentifier: finderBundleID)
        guard let target = finder.aeDesc else { return .notDetermined }
        let result = AEDeterminePermissionToAutomateTarget(
            target,
            AEEventClass(typeWildCard),
            AEEventID(typeWildCard),
            askingUser
        )
        return PermissionStatus(appleEventsResult: result) ?? .notDetermined
    }
}
