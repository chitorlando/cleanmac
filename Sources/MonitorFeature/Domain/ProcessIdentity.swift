import Foundation

/// How a process is shown: the app's name and icon when it belongs to one.
public struct ProcessIdentity: Equatable, Sendable {
    /// Display name, or `nil` to keep the process's own name.
    public let name: String?
    /// The app bundle or executable whose icon stands for the process.
    public let iconURL: URL?

    public init(name: String?, iconURL: URL?) {
        self.name = name
        self.iconURL = iconURL
    }
}
