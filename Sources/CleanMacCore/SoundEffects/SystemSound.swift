import Foundation

/// A sound that comes with macOS, played from where macOS keeps it and never copied into the app.
public enum SystemSound: Hashable, Sendable {
    /// One of the alert sounds in `/System/Library/Sounds`, by name, such as “Tink”.
    case alert(String)
    /// A sound file macOS keeps for one of its apps, such as Finder, and the alert sound that
    /// plays in its place when the file is missing: that place isn't public, so it may move.
    case file(URL, fallback: String)
}

public extension SystemSound {
    /// Folder of the sounds Finder plays, such as when it moves items to the Trash.
    static let finderSounds = URL(
        filePath: "/System/Library/Components/CoreAudio.component/Contents/SharedSupport/SystemSounds/finder",
        directoryHint: .isDirectory
    )

    /// The sound Finder plays when it moves items to the Trash.
    static let moveToTrash = SystemSound.file(finderSounds.appending(path: "move to trash.aif"), fallback: "Pop")

    /// The sound Finder plays when it empties the Trash.
    static let emptyTrash = SystemSound.file(finderSounds.appending(path: "empty trash.aif"), fallback: "Glass")
}
