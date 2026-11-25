import CleanMacCore
import Foundation
import LargeFilesFeature
import os

/// Emits a fixed list of scan events, optionally leaving the stream open, and remembers where
/// it was asked to look and for which sizes.
struct StubLargeFileScanner: LargeFileScanning {
    let events: [LargeFileScanEvent]
    var finishes = true
    /// What a scan limited to a folder emits instead of `events`. Such a scan always finishes.
    var folderEvents: [LargeFileScanEvent] = []
    /// Folders the scan can't be limited to. It can to any other URL.
    var unscannableFolders: Set<URL> = []

    let scopes = OSAllocatedUnfairLock<[ScanScope]>(initialState: [])
    let minimumSizes = OSAllocatedUnfairLock<[Int64]>(initialState: [])

    /// Scopes of the scans started so far, oldest first.
    var scannedScopes: [ScanScope] { scopes.withLock { $0 } }
    /// Smallest size each scan started so far looked for, oldest first.
    var scannedMinimumSizes: [Int64] { minimumSizes.withLock { $0 } }

    func scope(limitedTo url: URL) -> ScanScope? {
        unscannableFolders.contains(url) ? nil : .folder(url)
    }

    func scan(_ scope: ScanScope, criteria: LargeFileCriteria) -> AsyncStream<LargeFileScanEvent> {
        scopes.withLock { $0.append(scope) }
        minimumSizes.withLock { $0.append(criteria.minimumSize) }
        let isHome = scope == .home
        return AsyncStream { continuation in
            (isHome ? events : folderEvents).forEach { continuation.yield($0) }
            if finishes || !isHome { continuation.finish() }
        }
    }
}
