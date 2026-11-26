import Foundation

/// Asks Finder to empty the Trash, exactly as Empty Trash in its menu does.
///
/// CleanMac never deletes anything in the Trash itself: the script names no file, so no
/// mistake in a path can erase anything but what the user put in the Trash. Finder empties
/// every bin of the current user, on this Mac and on the mounted volumes, and no one else's.
/// It deals with locked items and items in use the way the user knows, and it doesn't need
/// Full Disk Access, only the permission to control Finder that CleanMac already asks for.
public struct FinderTrashEmptier: TrashEmptying {
    private static let osascript = URL(filePath: "/usr/bin/osascript")

    /// A big Trash takes Finder a while, longer than the two minutes Apple Events wait by default.
    static let scriptLines = [
        "with timeout of 3600 seconds",
        "tell application \"Finder\" to empty trash",
        "end timeout"
    ]

    private let runner: any CommandRunning

    public init(runner: any CommandRunning = CommandRunner()) {
        self.runner = runner
    }

    public func emptyTrash() async throws {
        try await runner.run(Self.osascript, arguments: Self.scriptLines.flatMap { ["-e", $0] })
    }
}
