import Foundation

/// Asks Finder to move an item to the Trash. Finder requests an administrator password
/// for protected items, such as App Store apps, and keeps "Put Back" available.
public struct FinderTrashRemover: ItemRemoving {
    private static let osascript = URL(filePath: "/usr/bin/osascript")

    /// The path arrives as an argument, so it is never interpreted as AppleScript.
    private static let scriptLines = [
        "on run argv",
        "set itemToTrash to (POSIX file (item 1 of argv)) as alias",
        "tell application \"Finder\" to delete itemToTrash",
        "end run"
    ]

    private let runner: CommandRunner

    public init(runner: CommandRunner = CommandRunner()) {
        self.runner = runner
    }

    public func remove(_ url: URL) async throws {
        let scriptArguments = Self.scriptLines.flatMap { ["-e", $0] }
        try await runner.run(Self.osascript, arguments: scriptArguments + [url.path])
    }
}
