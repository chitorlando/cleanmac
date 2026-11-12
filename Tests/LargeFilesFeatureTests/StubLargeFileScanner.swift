import Foundation
import LargeFilesFeature
import os

/// Emits a fixed list of scan events, optionally leaving the stream open, and remembers where
/// it was asked to look.
struct StubLargeFileScanner: LargeFileScanning {
    let events: [LargeFileScanEvent]
    var finishes = true
    var criteria = LargeFileCriteria()
    /// What a scan limited to a folder emits instead of `events`. Such a scan always finishes.
    var folderEvents: [LargeFileScanEvent] = []
    /// Folders the scan can't be limited to. It can to any other URL.
    var unscannableFolders: Set<URL> = []

    let scopes = OSAllocatedUnfairLock<[LargeFileScanScope]>(initialState: [])

    /// Scopes of the scans started so far, oldest first.
    var scannedScopes: [LargeFileScanScope] { scopes.withLock { $0 } }

    func scope(limitedTo url: URL) -> LargeFileScanScope? {
        unscannableFolders.contains(url) ? nil : .folder(url)
    }

    func scan(_ scope: LargeFileScanScope) -> AsyncStream<LargeFileScanEvent> {
        scopes.withLock { $0.append(scope) }
        let isHome = scope == .home
        return AsyncStream { continuation in
            (isHome ? events : folderEvents).forEach { continuation.yield($0) }
            if finishes || !isHome { continuation.finish() }
        }
    }
}
