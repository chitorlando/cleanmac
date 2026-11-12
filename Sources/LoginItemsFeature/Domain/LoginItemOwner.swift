import Foundation

/// The app a launchd item belongs to, shown with its name and icon.
public struct LoginItemOwner: Hashable, Sendable {
    public let appURL: URL
    public let name: String

    public init(appURL: URL, name: String) {
        self.appURL = appURL
        self.name = name
    }
}
