import Foundation

/// An app that is open, as the system reports it.
public struct RunningApp: Hashable, Sendable {
    /// Standardized URL of the bundle it runs from. The system runs some apps from a
    /// random path, so it is not always where the app is.
    public let url: URL
    public let bundleID: String?

    public init(url: URL, bundleID: String?) {
        self.url = url
        self.bundleID = bundleID
    }
}
