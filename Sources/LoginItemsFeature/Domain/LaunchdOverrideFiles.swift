import Foundation

/// Reads launchd's overrides from the property lists it keeps them in, which anyone can read
/// and `launchctl print-disabled` lists: `disabled.<uid>.plist` for the agents of the user's
/// session and `disabled.plist` for the daemons of the system.
///
/// Only reads the files: it never asks launchd anything. A missing or unreadable file, or
/// one that isn't a dictionary, has no overrides, and values that aren't Booleans are skipped.
public struct LaunchdOverrideFiles: LaunchOverridesReading {
    /// Where launchd keeps the overrides.
    public static let standardFolder = URL(filePath: "/var/db/com.apple.xpc.launchd")

    private let folder: URL
    private let userID: uid_t

    /// - Parameters:
    ///   - folder: Where the files are.
    ///   - userID: The user whose session's agents to read the overrides of.
    public init(folder: URL = standardFolder, userID: uid_t = getuid()) {
        self.folder = folder
        self.userID = userID
    }

    public func overrides(for kind: LaunchItemKind) -> [String: Bool] {
        guard
            let data = try? Data(contentsOf: fileURL(for: kind)),
            let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any]
        else { return [:] }
        return plist.compactMapValues { $0 as? Bool }
    }

    private func fileURL(for kind: LaunchItemKind) -> URL {
        switch kind {
        case .agent: folder.appending(path: "disabled.\(userID).plist")
        case .daemon: folder.appending(path: "disabled.plist")
        }
    }
}
