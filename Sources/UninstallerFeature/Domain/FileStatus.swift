import Darwin
import Foundation

/// Low-level status of an item, read without following symbolic links.
struct FileStatus {
    private let mode: mode_t
    private let flags: UInt32

    init?(url: URL) {
        var info = stat()
        guard lstat(url.path, &info) == 0 else { return nil }
        mode = info.st_mode
        flags = info.st_flags
    }

    var isSymbolicLink: Bool { mode & S_IFMT == S_IFLNK }

    /// Protected by System Integrity Protection, so it cannot be removed.
    var isSystemRestricted: Bool { flags & UInt32(SF_RESTRICTED) != 0 }
}
