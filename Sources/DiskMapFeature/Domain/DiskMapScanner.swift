import CleanMacCore
import Foundation

/// Walks a folder in the background, reporting how much it has measured, and ends with the map of its contents.
public struct DiskMapScanner: DiskMapScanning {
    public static let defaultProgressInterval = 500

    /// Folder the map starts from.
    public let root: URL
    private let walker: any FileWalking
    private let grouping: SmallItemGrouping
    private let progressInterval: Int

    public init(
        root: URL = FileManager.default.homeDirectoryForCurrentUser,
        walker: any FileWalking,
        grouping: SmallItemGrouping = SmallItemGrouping(),
        progressInterval: Int = defaultProgressInterval
    ) {
        self.root = root
        self.walker = walker
        self.grouping = grouping
        self.progressInterval = max(1, progressInterval)
    }

    /// Starts the scan. Ending the iteration of the stream cancels the walk, and no map is built.
    public func scan() -> AsyncStream<DiskMapScanEvent> {
        let scanner = self
        return AsyncStream { continuation in
            let task = Task.detached(priority: .utility) {
                scanner.run(reportingTo: continuation)
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    private func run(reportingTo continuation: AsyncStream<DiskMapScanEvent>.Continuation) {
        let builder = DiskTreeBuilder(root: root, grouping: grouping)
        var progress = DiskMapProgress()
        walker.walk(root) { record in
            guard !Task.isCancelled else { return false }
            builder.add(record)
            progress.add(record)
            if progress.fileCount.isMultiple(of: progressInterval) {
                continuation.yield(.progress(progress))
            }
            return true
        }
        guard !Task.isCancelled else { return }
        if progress.fileCount == 0 || !progress.fileCount.isMultiple(of: progressInterval) {
            continuation.yield(.progress(progress))
        }
        continuation.yield(.finished(builder.build()))
    }
}
