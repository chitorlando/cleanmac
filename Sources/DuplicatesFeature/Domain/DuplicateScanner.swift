import CleanMacCore
import Foundation

/// Walks the home folder, or one folder of it, in the background and reports the groups of
/// identical files it contains.
///
/// A folder is scanned on its own under the rules of the home scan: what the walker skips
/// stays skipped inside it, and a folder the home scan never walks is not scanned at all
/// (see `ScanScopePolicy`). Each scan gets a policy and a walker that leave out the same
/// folders: the policy's own and those left out of that scan.
///
/// Files are compared in three passes, each more expensive and on fewer files:
/// same size, same first 64 KB, and finally the same SHA-256 of the whole file.
/// The copies of each group found are then checked for APFS clones, which share their data.
public struct DuplicateScanner: DuplicateScanning {
    /// Smallest size of the files compared until the user chooses another. Smaller files take
    /// long to compare and free little space.
    public static let defaultMinimumSize: Int64 = 1_000_000
    public static let defaultProgressInterval = 500

    private let scopePolicy: ScanScopePolicy
    private let makeWalker: @Sendable ([URL]) -> any FileWalking
    private let metadataReader: any FileMetadataReading
    private let cloneInfoReader: any CloneInfoReading
    private let matcher: ContentMatcher
    private let progressInterval: Int

    /// - Parameters:
    ///   - scopePolicy: Says which folders every scan may look in, starting with the home folder.
    ///   - makeWalker: The walker of a scan, given the folders it skips with everything inside.
    public init(
        scopePolicy: ScanScopePolicy,
        makeWalker: @escaping @Sendable (_ excludedDirectories: [URL]) -> any FileWalking = {
            FileSystemWalker(excludedDirectories: $0)
        },
        hasher: any FileHashing = SHA256FileHasher(),
        metadataReader: any FileMetadataReading = LocalFileMetadataReader(),
        cloneInfoReader: any CloneInfoReading = APFSCloneInfoReader(),
        progressInterval: Int = defaultProgressInterval
    ) {
        self.scopePolicy = scopePolicy
        self.makeWalker = makeWalker
        self.metadataReader = metadataReader
        self.cloneInfoReader = cloneInfoReader
        self.matcher = ContentMatcher(hasher: hasher)
        self.progressInterval = max(1, progressInterval)
    }

    public func scope(limitedTo url: URL, excluding excludedFolders: [URL]) -> ScanScope? {
        scopePolicy.excluding(excludedFolders).scope(limitedTo: url)
    }

    /// Starts scanning `scope`, without `excludedFolders`, for identical files of
    /// `minimumSize` bytes or more. Ending the iteration of the stream cancels the scan.
    ///
    /// The policy checks the scope again here, right before the walk: its folder may have
    /// changed since the scope was made, and the scope may not come from `scope(limitedTo:)`.
    /// A folder that can't be scanned on its own, or no longer can, reports nothing.
    public func scan(
        _ scope: ScanScope,
        excluding excludedFolders: [URL],
        minimumSize: Int64
    ) -> AsyncStream<DuplicateScanEvent> {
        let scanner = self
        let scopePolicy = self.scopePolicy.excluding(excludedFolders)
        let walker = makeWalker(scopePolicy.excludedDirectories)
        return AsyncStream { continuation in
            let task = Task.detached(priority: .utility) {
                if let root = scopePolicy.folder(of: scope) {
                    scanner.run(in: root, walker: walker, minimumSize: minimumSize, reportingTo: continuation)
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    private func run(
        in root: URL,
        walker: any FileWalking,
        minimumSize: Int64,
        reportingTo continuation: AsyncStream<DuplicateScanEvent>.Continuation
    ) {
        var progress = DuplicateScanProgress()
        let records = collectLargeEnoughFiles(
            in: root,
            walker: walker,
            minimumSize: minimumSize,
            progress: &progress,
            continuation: continuation
        )
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
        walker: any FileWalking,
        minimumSize: Int64,
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
