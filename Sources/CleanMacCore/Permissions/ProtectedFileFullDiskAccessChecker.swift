import Darwin
import Foundation

/// `FullDiskAccessChecking` that tries to open files only Full Disk Access lets an app open.
///
/// macOS never shows a dialog for Full Disk Access: the attempt is simply refused, so the
/// check is silent. The files are opened and closed at once, without reading a byte.
/// A refused attempt is also reported to be what makes an app appear in the Full Disk
/// Access list of System Settings, so the user only has to turn it on there.
public struct ProtectedFileFullDiskAccessChecker: FullDiskAccessChecking {
    /// The system's privacy database, which exists on every Mac, and Safari's bookmarks as a
    /// second witness in case the first one moves in a future macOS.
    public static var defaultProbes: [URL] {
        [
            URL(filePath: "/Library/Application Support/com.apple.TCC/TCC.db"),
            FileManager.default.homeDirectoryForCurrentUser.appending(path: "Library/Safari/Bookmarks.plist")
        ]
    }

    private let probes: [URL]
    private let access: @Sendable (URL) -> ProtectedFileAccess

    /// - Parameters:
    ///   - probes: Protected files to try, in order, until one gives an answer.
    ///   - access: Tries to open a file.
    public init(
        probes: [URL] = Self.defaultProbes,
        access: @escaping @Sendable (URL) -> ProtectedFileAccess = Self.open
    ) {
        self.probes = probes
        self.access = access
    }

    /// The first probe that exists decides. With none, access can't be shown, so it counts as missing.
    public func hasFullDiskAccess() -> Bool {
        for probe in probes {
            switch access(probe) {
            case .allowed: return true
            case .denied: return false
            case .missing: continue
            }
        }
        return false
    }

    /// Opens the file for reading and closes it straight away.
    public static func open(_ url: URL) -> ProtectedFileAccess {
        let descriptor = Darwin.open(url.path(percentEncoded: false), O_RDONLY | O_NONBLOCK)
        guard descriptor >= 0 else {
            return errno == ENOENT ? .missing : .denied
        }
        close(descriptor)
        return .allowed
    }
}
