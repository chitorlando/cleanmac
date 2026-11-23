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

public extension RunningApp {
    /// The name of its bundle without the extension, such as "Google Chrome Canary".
    var name: String { url.deletingPathExtension().lastPathComponent }

    /// Whether it runs from inside another app's bundle, as the helpers of a browser do.
    /// A helper opens and closes with the app that holds it, and the user can't quit it.
    var isHelper: Bool { (url.deletingLastPathComponent().path + "/").contains(".app/") }
}
