import CleanMacCore
import Foundation

/// Walks the home folder, or one folder of it, in the background and reports the groups of
/// identical files it contains.
///
/// A folder is scanned on its own under the rules of the home scan: what the walker skips
/// stays skipped inside it, and a folder the home scan never walks is not scanned at all
/// (see `ScanScopePolicy`).
///
/// Files are compared in three passes, each more expensive and on fewer files:
/// same size, same first 64 KB, and finally the same SHA-256 of the whole file.
/// The copies of each group found are then checked for APFS clones, which share their data.
public struct DuplicateScanner: DuplicateScanning {
    /// Smaller files take long to compare and free little space.
    public static let defaultMinimumSize: Int64 = 1_000_000
    public static let defaultProgressInterval = 500

    private let home: URL
    private let walker: any FileWalking
    private let scopePolicy: ScanScopePolicy
    private let metadataReader: any FileMetadataReading
    private let cloneInfoReader: any CloneInfoReading
    private let matcher: ContentMatcher
    private let minimumSize: Int64
    private let progressInterval: Int

    /// - Parameter excludedDirectories: Folders the walker skips with everything inside. They
    ///   must be the ones the walker was given, so none of them is scanned on its own either.
    public init(
        home: URL,
        walker: any FileWalking,
        excludedDirectories: [URL],
        hasher: any FileHashing = SHA256FileHasher(),
        metadataReader: any FileMetadataReading = LocalFileMetadataReader(),
        cloneInfoReader: any CloneInfoReading = APFSCloneInfoReader(),
        minimumSize: Int64 = defaultMinimumSize,
        progressInterval: Int = defaultProgressInterval
    ) {
        self.home = home
        self.walker = walker
        self.scopePolicy = ScanScopePolicy(home: home, excludedDirectories: excludedDirectories)
        self.metadataReader = metadataReader
        self.cloneInfoReader = cloneInfoReader
        self.matcher = ContentMatcher(hasher: hasher)
        self.minimumSize = minimumSize
        self.progressInterval = max(1, progressInterval)
    }

    public func scope(limitedTo url: URL) -> DuplicateScanScope? {
        scopePolicy.scope(limitedTo: url)
    }

    /// Starts scanning `scope`. Ending the iteration of the stream cancels the scan.
    ///
    /// A folder that can't be scanned on its own, or no longer can, reports nothing.
    public func scan(_ scope: DuplicateScanScope) -> AsyncStream<DuplicateScanEvent> {
        let scanner = self
        return AsyncStream { continuation in
            let task = Task.detached(priority: .utility) {
                if let root = scanner.root(of: scope) {
                    scanner.run(in: root, reportingTo: continuation)
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    /// The folder to walk for `scope`, or `nil` for a folder the home scan never walks.
    ///
    /// The folder is checked again here, right before walking it: it may have changed since
    /// its scope was made, and the scope may not come from `scope(limitedTo:)`.
    private func root(of scope: DuplicateScanScope) -> URL? {
        switch scope {
        case .home: home
        case .folder(let folder): scopePolicy.allows(folder) ? folder : nil
        }
    }

    private func run(in root: URL, reportingTo continuation: AsyncStream<DuplicateScanEvent>.Continuation) {
        var progress = DuplicateScanProgress()
        let records = collectLargeEnoughFiles(in: root, progress: &progress, continuation: continuation)
        continuation.yield(.progress(progress))

        for sizeGroup in SizeGrouping.candidateGroups(records) {
            guard !Task.isCancelled else { return }
            let candidates = DuplicateCandidate.unique(sizeGroup, reader: metadataReader)
            let groups = matcher.duplicates(among: candidates) { bytes in
                progress.hashedBytes += bytes
                continuation.yield(.progress(progress))
            }
            guard !Task.isCancelled else { return }
            groups.forEach { continuation.yield(.found($0.withCloneInfo(from: cloneInfoReader))) }
        }
    }

    private func collectLargeEnoughFiles(
        in root: URL,
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
