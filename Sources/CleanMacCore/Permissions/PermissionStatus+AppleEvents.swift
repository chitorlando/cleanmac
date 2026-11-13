import CoreServices

extension PermissionStatus {
    /// The status that `AEDeterminePermissionToAutomateTarget` returns, or `nil` for errors
    /// that say nothing about the permission, such as the target app not running.
    public init?(appleEventsResult result: OSStatus) {
        switch result {
        case noErr:
            self = .granted
        case OSStatus(errAEEventNotPermitted):
            self = .denied
        case OSStatus(errAEEventWouldRequireUserConsent):
            self = .notDetermined
        default:
            return nil
        }
    }
}
