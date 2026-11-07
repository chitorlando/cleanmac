import Foundation

/// Reads the identity of an application bundle.
public protocol AppInfoReading: Sendable {
    /// Returns `nil` when the bundle has no bundle identifier.
    func info(forAppAt url: URL) -> AppBundleInfo?
}
