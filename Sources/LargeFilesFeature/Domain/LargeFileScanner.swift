import CleanMacCore
import Foundation

/// Walks a folder in the background and reports the files that match the criteria as they're found.
public struct LargeFileScanner: LargeFileScanning {
    public static let defaultProgressInterval = 500

    private let root: URL
    private let criteria: LargeFileCriteria
    private let walker: any FileWalking
    private let progressInterval: Int

    public init(
        root: URL,
        criteria: LargeFileCriteria = LargeFileCriteria(),
        walker: any FileWalking,
        progressInterval: Int = defaultProgressInterval
    ) {
        self.root = root
        self.criteria = criteria
        self.walker = walker
        self.progressInterval = max(1, progressInterval)
    }

    /// Starts the scan. Ending the iteration of the stream cancels the walk.
    public func scan() -> AsyncStream<LargeFileScanEvent> {
        let root = root
        let criteria = criteria
        let walker = walker
        let interval = progressInterval
        return AsyncStream { continuation in
            let task = Task.detached(priority: .utility) {
                var scannedFiles = 0
                walker.walk(root) { record in
                    guard !Task.isCancelled else { return false }
                    scannedFiles += 1
                    if criteria.matches(record) {
                        continuation.yield(.found(LargeFile(record: record)))
                    }
                    if scannedFiles.isMultiple(of: interval) {
                        continuation.yield(.progress(scannedFiles: scannedFiles))
                    }
                    return true
                }
                if scannedFiles == 0 || !scannedFiles.isMultiple(of: interval) {
                    continuation.yield(.progress(scannedFiles: scannedFiles))
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }
}
