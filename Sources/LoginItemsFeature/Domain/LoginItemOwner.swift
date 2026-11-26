import Foundation

/// The app a launchd item belongs to, shown with its name and icon.
public struct LoginItemOwner: Hashable, Sendable {
    public let appURL: URL
    public let name: String

    public init(appURL: URL, name: String) {
        self.appURL = appURL
        self.name = name
    }

    /// The app at `appURL`, named after its bundle without the extension.
    public init(appURL: URL) {
        self.init(appURL: appURL, name: appURL.deletingPathExtension().lastPathComponent)
    }

    /// Whether it is the app at `url`, whichever way the path is written, such as with a
    /// trailing slash.
    public func isApp(at url: URL) -> Bool {
        appURL.standardizedFileURL.path == url.standardizedFileURL.path
    }
}
