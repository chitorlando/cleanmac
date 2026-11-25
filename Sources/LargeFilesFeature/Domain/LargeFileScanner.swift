import CleanMacCore
import Foundation

/// Walks a folder in the background and reports the files that match the criteria as they're found.
///
/// The folder is the home folder or one inside it, as the scope policy allows. Each scan gets
/// a policy and a walker that leave out the same folders, the policy's own and those left out
/// of that scan, so what a scan of the home folder skips is skipped in a single folder too.
public struct LargeFileScanner: LargeFileScanning {
    public static let defaultProgressInterval = 500

    private let scopePolicy: ScanScopePolicy
    private let makeWalker: @Sendable ([URL]) -> any FileWalking
    private let progressInterval: Int

    /// - Parameters:
    ///   - scopePolicy: Says which folders every scan may look in, starting with the home folder.
    ///   - makeWalker: The walker of a scan, given the folders it skips with everything inside.
    public init(
        scopePolicy: ScanScopePolicy,
        makeWalker: @escaping @Sendable (_ excludedDirectories: [URL]) -> any FileWalking = {
            FileSystemWalker(excludedDirectories: $0)
        },
        progressInterval: Int = defaultProgressInterval
    ) {
        self.scopePolicy = scopePolicy
        self.makeWalker = makeWalker
        self.progressInterval = max(1, progressInterval)
    }

    public func scope(limitedTo url: URL, excluding excludedFolders: [URL]) -> ScanScope? {
        scopePolicy.excluding(excludedFolders).scope(limitedTo: url)
    }

    /// Starts the scan. Ending the iteration of the stream cancels the walk.
    ///
    /// The policy checks the scope again here, when the walk begins: a folder that can no
    /// longer be scanned, because it's gone, is now a link to somewhere else or is left out,
    /// reports no files.
    public func scan(
        _ scope: ScanScope,
        excluding excludedFolders: [URL],
        criteria: LargeFileCriteria
    ) -> AsyncStream<LargeFileScanEvent> {
        let scopePolicy = self.scopePolicy.excluding(excludedFolders)
        let walker = makeWalker(scopePolicy.excludedDirectories)
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
