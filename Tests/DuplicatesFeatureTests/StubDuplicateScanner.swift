import DuplicatesFeature
import Foundation
import os

/// Emits a fixed list of scan events whatever the scope, optionally leaving the stream open,
/// and remembers the scopes it was asked to scan.
struct StubDuplicateScanner: DuplicateScanning {
    /// The home folder of the stub: asked for as a folder, it gives the whole scope.
    static let home = URL(filePath: "/Users/test")

    private struct State: Sendable {
        var scannedScopes: [DuplicateScanScope] = []
        var refusedFolders: Set<URL>
    }

    private let events: [DuplicateScanEvent]
    private let finishes: Bool
    private let state: OSAllocatedUnfairLock<State>

    /// - Parameter refusedFolders: Folders that can't be scanned on their own.
    init(events: [DuplicateScanEvent], finishes: Bool = true, refusedFolders: Set<URL> = []) {
        self.events = events
        self.finishes = finishes
        state = OSAllocatedUnfairLock(initialState: State(refusedFolders: refusedFolders))
    }

    /// The scope of every scan started so far, in order.
    var scannedScopes: [DuplicateScanScope] { state.withLock { $0.scannedScopes } }

    /// From now on, the folder at `url` can't be scanned on its own, as if it were gone.
    func refuse(_ url: URL) {
        state.withLock { _ = $0.refusedFolders.insert(url) }
    }

    func scope(limitedTo url: URL) -> DuplicateScanScope? {
        guard !state.withLock({ $0.refusedFolders.contains(url) }) else { return nil }
        return url == Self.home ? .home : .folder(url)
    }

    func scan(_ scope: DuplicateScanScope) -> AsyncStream<DuplicateScanEvent> {
        state.withLock { $0.scannedScopes.append(scope) }
        return AsyncStream { continuation in
            events.forEach { continuation.yield($0) }
            if finishes { continuation.finish() }
        }
    }
}
