import Foundation

/// A folder whose property lists tell launchd what to start.
public struct LaunchFolder: Hashable, Sendable {
    public let url: URL
    public let scope: LaunchScope
    public let kind: LaunchItemKind

    public init(url: URL, scope: LaunchScope, kind: LaunchItemKind) {
        self.url = url
        self.scope = scope
        self.kind = kind
    }
}

public extension LaunchFolder {
    /// The user's agents, then the agents and daemons shared by every user.
    /// `/System/Library` is left out: it belongs to macOS and is never shown.
    static func standard(home: URL, library: URL = URL(filePath: "/Library")) -> [LaunchFolder] {
        [
            LaunchFolder(url: home.appending(path: "Library/LaunchAgents"), scope: .currentUser, kind: .agent),
            LaunchFolder(url: library.appending(path: "LaunchAgents"), scope: .allUsers, kind: .agent),
            LaunchFolder(url: library.appending(path: "LaunchDaemons"), scope: .allUsers, kind: .daemon)
        ]
    }
}
