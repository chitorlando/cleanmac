import Darwin
import Foundation

/// Folders a walk couldn't look into, kept from when the enumerator reports them until the
/// walk hands them on.
///
/// The enumerator reports errors to a handler that can't reach the walk's own closures, so
/// they wait here. A walk runs on a single thread: the lock only makes the log safe to hand
/// to that handler.
final class UnreadableFolderLog: @unchecked Sendable {
    private let lock = NSLock()
    private var folders: [URL] = []

    /// Keeps the folder at `url` when `error` means it can't be read: privacy protection or its
    /// permissions keep the walk out. Other errors are ignored, as are folders only in the cloud,
    /// which can't be listed without downloading them but hold nothing on this Mac.
    func record(_ url: URL, failingWith error: any Error) {
        guard CleanupFailureClassifier.kind(of: error) == .protectedByMacOS, !Self.isDataless(url) else { return }
        lock.lock()
        folders.append(url)
        lock.unlock()
    }

    /// Hands the folders kept so far to `report`, in the order they were found, and forgets them.
    func flush(into report: (URL) -> Void) {
        lock.lock()
        let found = folders
        folders.removeAll()
        lock.unlock()
        found.forEach(report)
    }

    /// Whether the item is a placeholder whose contents are only in the cloud.
    private static func isDataless(_ url: URL) -> Bool {
        var status = stat()
        guard lstat(url.path(percentEncoded: false), &status) == 0 else { return false }
        return status.st_flags & UInt32(SF_DATALESS) != 0
    }
}
