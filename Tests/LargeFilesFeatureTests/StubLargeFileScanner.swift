import CleanMacCore
import Foundation
import LargeFilesFeature
import os

/// Emits a fixed list of scan events, optionally leaving the stream open, and remembers where
/// it was asked to look, for which sizes and leaving out which folders.
struct StubLargeFileScanner: LargeFileScanning {
    let events: [LargeFileScanEvent]
    var finishes = true
    /// What a scan limited to a folder emits instead of `events`. Such a scan always finishes.
    var folderEvents: [LargeFileScanEvent] = []
    /// Folders the scan can't be limited to. It can to any other URL that isn't left out.
    var unscannableFolders: Set<URL> = []

    let scopes = OSAllocatedUnfairLock<[ScanScope]>(initialState: [])
    let minimumSizes = OSAllocatedUnfairLock<[Int64]>(initialState: [])
    let excludedFolderLists = OSAllocatedUnfairLock<[[URL]]>(initialState: [])

    /// Scopes of the scans started so far, oldest first.
    var scannedScopes: [ScanScope] { scopes.withLock { $0 } }
    /// Smallest size each scan started so far looked for, oldest first.
    var scannedMinimumSizes: [Int64] { minimumSizes.withLock { $0 } }
    /// Folders each scan started so far left out, oldest first.
    var scannedExcludedFolders: [[URL]] { excludedFolderLists.withLock { $0 } }

    /// Refuses the unscannable folders and the folders left out themselves, not what's inside them.
    func scope(limitedTo url: URL, excluding excludedFolders: [URL]) -> ScanScope? {
        unscannableFolders.contains(url) || excludedFolders.contains(url) ? nil : .folder(url)
    }

    func scan(
        _ scope: ScanScope,
        excluding excludedFolders: [URL],
        criteria: LargeFileCriteria
    ) -> AsyncStream<LargeFileScanEvent> {
        scopes.withLock { $0.append(scope) }
        minimumSizes.withLock { $0.append(criteria.minimumSize) }
        excludedFolderLists.withLock { $0.append(excludedFolders) }
        let isHome = scope == .home
        return AsyncStream { continuation in
            (isHome ? events : folderEvents).forEach { continuation.yield($0) }
            if finishes || !isHome { continuation.finish() }
        }
    }
}
