import CleanMacCore
import Foundation

/// Walks a folder in the background and reports the groups of identical files it contains.
///
/// Files are compared in three passes, each more expensive and on fewer files:
/// same size, same first 64 KB, and finally the same SHA-256 of the whole file.
public struct DuplicateScanner: DuplicateScanning {
    /// Smaller files take long to compare and free little space.
    public static let defaultMinimumSize: Int64 = 1_000_000
    public static let defaultProgressInterval = 500

    private let root: URL
    private let walker: any FileWalking
    private let metadataReader: any FileMetadataReading
    private let matcher: ContentMatcher
    private let minimumSize: Int64
    private let progressInterval: Int

    public init(
        root: URL,
        walker: any FileWalking,
        hasher: any FileHashing = SHA256FileHasher(),
        metadataReader: any FileMetadataReading = LocalFileMetadataReader(),
        minimumSize: Int64 = defaultMinimumSize,
        progressInterval: Int = defaultProgressInterval
    ) {
        self.root = root
        self.walker = walker
        self.metadataReader = metadataReader
        self.matcher = ContentMatcher(hasher: hasher)
        self.minimumSize = minimumSize
        self.progressInterval = max(1, progressInterval)
    }

    /// Starts the scan. Ending the iteration of the stream cancels it.
    public func scan() -> AsyncStream<DuplicateScanEvent> {
        let scanner = self
        return AsyncStream { continuation in
            let task = Task.detached(priority: .utility) {
                scanner.run(reportingTo: continuation)
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    private func run(reportingTo continuation: AsyncStream<DuplicateScanEvent>.Continuation) {
        var progress = DuplicateScanProgress()
        let records = collectLargeEnoughFiles(progress: &progress, continuation: continuation)
        continuation.yield(.progress(progress))

        for sizeGroup in SizeGrouping.candidateGroups(records) {
            guard !Task.isCancelled else { return }
            let candidates = DuplicateCandidate.unique(sizeGroup, reader: metadataReader)
            let groups = matcher.duplicates(among: candidates) { bytes in
                progress.hashedBytes += bytes
                continuation.yield(.progress(progress))
            }
            guard !Task.isCancelled else { return }
            groups.forEach { continuation.yield(.found($0)) }
        }
    }

    private func collectLargeEnoughFiles(
        progress: inout DuplicateScanProgress,
        continuation: AsyncStream<DuplicateScanEvent>.Continuation
    ) -> [FileRecord] {
        var records: [FileRecord] = []
        var scannedFiles = 0
        walker.walk(root) { record in
            guard !Task.isCancelled else { return false }
            scannedFiles += 1
            if record.size >= minimumSize {
                records.append(record)
            }
            if scannedFiles.isMultiple(of: progressInterval) {
                continuation.yield(.progress(DuplicateScanProgress(scannedFiles: scannedFiles)))
            }
            return true
        }
        progress.scannedFiles = scannedFiles
        return records
    }
}
