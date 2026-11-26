import Darwin
import Foundation

/// `ItemPresenceChecking` that asks the file system and reads why it couldn't find the item.
///
/// Symbolic links are followed, so a link to something that is gone counts as missing.
public struct FileSystemItemPresenceChecker: ItemPresenceChecking {
    public init() {}

    public func presence(of url: URL) -> ItemPresence {
        var status = stat()
        guard stat(url.path, &status) != 0 else { return .present }
        switch errno {
        case ENOENT, ENOTDIR:
            return .missing
        default:
            // No permission to enter a folder on the way, among others: the item may well be there.
            return .unknown
        }
    }
}
