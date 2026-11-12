import DuplicatesFeature
import Foundation
import os

/// Emits a fixed list of scan events whatever the scope, optionally leaving the stream open,
/// and remembers the scopes it was asked to scan.
struct StubDuplicateScanner: DuplicateScanning {
    /// The home folder of the stub: asked for as a folder, it gives the whole scope.
    static let home = URL(filePath: "/Users/test")

    private let events: [DuplicateScanEvent]
    private let finishes: Bool
    private let refusedFolders: Set<URL>
    private let scopes = OSAllocatedUnfairLock<[DuplicateScanScope]>(initialState: [])

    /// - Parameter refusedFolders: Folders that can't be scanned on their own.
    init(events: [DuplicateScanEvent], finishes: Bool = true, refusedFolders: Set<URL> = []) {
        self.events = events
        self.finishes = finishes
        self.refusedFolders = refusedFolders
    }

    /// The scope of every scan started so far, in order.
    var scannedScopes: [DuplicateScanScope] { scopes.withLock { $0 } }

    func scope(limitedTo url: URL) -> DuplicateScanScope? {
        guard !refusedFolders.contains(url) else { return nil }
        return url == Self.home ? .home : .folder(url)
    }

    func scan(_ scope: DuplicateScanScope) -> AsyncStream<DuplicateScanEvent> {
        scopes.withLock { $0.append(scope) }
        return AsyncStream { continuation in
            events.forEach { continuation.yield($0) }
            if finishes { continuation.finish() }
        }
    }
}
