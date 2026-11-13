import CleanMacCore
import Foundation

/// Walks a folder in the background and reports the files that match the criteria as they're found.
///
/// The folder is the home folder or one inside it, as the scope policy allows. The same walker
/// walks both, so what a scan of the home folder skips is skipped in a single folder too.
public struct LargeFileScanner: LargeFileScanning {
    public static let defaultProgressInterval = 500

    public let criteria: LargeFileCriteria
    private let scopePolicy: ScanScopePolicy
    private let walker: any FileWalking
    private let progressInterval: Int

    /// - Parameters:
    ///   - scopePolicy: Says which folders the scan may look in, starting with the home folder.
    ///     Give it the folders that `walker` excludes.
    public init(
        scopePolicy: ScanScopePolicy,
        criteria: LargeFileCriteria = LargeFileCriteria(),
        walker: any FileWalking,
        progressInterval: Int = defaultProgressInterval
    ) {
        self.scopePolicy = scopePolicy
        self.criteria = criteria
        self.walker = walker
        self.progressInterval = max(1, progressInterval)
    }

    public func scope(limitedTo url: URL) -> LargeFileScanScope? {
        scopePolicy.scope(limitedTo: url)
    }

    /// Starts the scan. Ending the iteration of the stream cancels the walk.
    ///
    /// The policy checks the scope again here, when the walk begins: a folder that can no
    /// longer be scanned, because it's gone or is now a link to somewhere else, reports no files.
    public func scan(_ scope: LargeFileScanScope) -> AsyncStream<LargeFileScanEvent> {
        let scopePolicy = scopePolicy
        let criteria = criteria
        let walker = walker
        let interval = progressInterval
        return AsyncStream { continuation in
            let task = Task.detached(priority: .utility) {
                var scannedFiles = 0
                if let folder = scopePolicy.folder(of: scope) {
                    walker.walk(folder) { record in
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
