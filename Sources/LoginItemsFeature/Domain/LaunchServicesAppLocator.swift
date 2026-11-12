import AppKit

/// `AppLocating` backed by Launch Services, which already knows every installed app.
public struct LaunchServicesAppLocator: AppLocating {
    public init() {}

    public func appURL(forBundleID bundleID: String) -> URL? {
        NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID)
    }
}
