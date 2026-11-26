import CleanMacCore
import Foundation

/// Walks a folder in the background, reporting how much it has measured, and ends with the map of its contents.
///
/// Folders the walk can't read are in the map too, marked as unreadable, so their space isn't
/// silently missing. So are the protected folders a scan leaves out (see `ProtectedFolders`).
public struct DiskMapScanner: DiskMapScanning {
    public static let defaultProgressInterval = 500

    /// Folder the map starts from.
    public let root: URL
    private let protectedFolders: ProtectedFolders
    private let makeWalker: @Sendable ([URL]) -> any FileWalking
    private let grouping: SmallItemGrouping
    private let progressInterval: Int

    /// Scanner that walks everything under `root` with `walker`.
    public init(
        root: URL = FileManager.default.homeDirectoryForCurrentUser,
        walker: any FileWalking,
        grouping: SmallItemGrouping = SmallItemGrouping(),
        progressInterval: Int = defaultProgressInterval
    ) {
        self.init(
            root: root,
            protectedFolders: .none,
            makeWalker: { _ in walker },
            grouping: grouping,
            progressInterval: progressInterval
        )
    }

    /// - Parameters:
    ///   - protectedFolders: Folders each scan leaves out until CleanMac has Full Disk Access.
    ///   - makeWalker: The walker of a scan, given the folders it must skip with everything inside.
    public init(
        root: URL = FileManager.default.homeDirectoryForCurrentUser,
        protectedFolders: ProtectedFolders,
        makeWalker: @escaping @Sendable (_ excludedDirectories: [URL]) -> any FileWalking,
        grouping: SmallItemGrouping = SmallItemGrouping(),
        progressInterval: Int = defaultProgressInterval
    ) {
        self.root = root
        self.protectedFolders = protectedFolders
        self.makeWalker = makeWalker
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
        let leftOut = protectedFolders.foldersToLeaveOut()
        leftOut.forEach { builder.addUnreadableFolder(at: $0) }
        var progress = DiskMapProgress()
        makeWalker(leftOut).walk(
            root,
            visit: { record in
                guard !Task.isCancelled else { return false }
                builder.add(record)
                progress.add(record)
                if progress.fileCount.isMultiple(of: progressInterval) {
                    continuation.yield(.progress(progress))
                }
                return true
            },
            unreadable: { builder.addUnreadableFolder(at: $0) }
        )
        guard !Task.isCancelled else { return }
        if progress.fileCount == 0 || !progress.fileCount.isMultiple(of: progressInterval) {
            continuation.yield(.progress(progress))
        }
        continuation.yield(.finished(builder.build()))
    }
}
