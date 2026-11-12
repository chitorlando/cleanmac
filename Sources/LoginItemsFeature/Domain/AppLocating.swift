import Foundation

/// Finds an installed app by its bundle identifier.
public protocol AppLocating: Sendable {
    func appURL(forBundleID bundleID: String) -> URL?
}
