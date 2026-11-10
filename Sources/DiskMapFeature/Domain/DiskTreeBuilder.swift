import CleanMacCore
import Foundation

/// Builds the disk map of a folder from the files a walk finds, in any order.
///
/// Every folder adds up the size and files of everything inside it. Items too small to show
/// on their own are counted together as their folder's `otherItems`, as `grouping` decides,
/// and what's inside them is left out, so the map stays small even for millions of files.
public final class DiskTreeBuilder {
    private let root: FolderAccumulator
    private let rootPaths: [String]
    private let grouping: SmallItemGrouping
    private var lastFolderPath: String?
    private var lastFolder: FolderAccumulator?

    public init(root: URL, grouping: SmallItemGrouping = SmallItemGrouping()) {
        self.root = FolderAccumulator(url: root)
        self.rootPaths = Self.folderPaths(of: root)
        self.grouping = grouping
    }

    /// Adds a file or package found inside the root. Anything outside it is ignored.
    public func add(_ record: FileRecord) {
        let path = record.url.path(percentEncoded: false)
        guard let rootPath = rootPaths.first(where: path.hasPrefix) else { return }
        var relativePath = path.dropFirst(rootPath.count)
        if relativePath.hasSuffix("/") {
            relativePath = relativePath.dropLast()
        }
        guard !relativePath.isEmpty else { return }

        let folderPath = relativePath.lastIndex(of: "/").map { relativePath[..<$0] } ?? ""
        folder(at: String(folderPath)).add(DiskNode(record: record), grouping: grouping)
    }

    /// The map of everything added so far.
    public func build() -> DiskNode {
        root.node(grouping: grouping)
    }

    /// The folder at `path`, relative to the root, created as needed.
    /// Walks list a folder's files one after another, so the last one is kept at hand.
    private func folder(at path: String) -> FolderAccumulator {
        if path == lastFolderPath, let lastFolder {
            return lastFolder
        }
        let folder = path.split(separator: "/").reduce(root) { $0.subfolder(named: String($1)) }
        lastFolderPath = path
        lastFolder = folder
        return folder
    }

    /// Paths files inside `root` start with: its own and, when it goes through a symbolic link,
    /// its real one, which is what walks report. `/var/folders` is really `/private/var/folders`.
    private static func folderPaths(of root: URL) -> [String] {
        let path = root.standardizedFileURL.path(percentEncoded: false)
        let canonicalPath = (try? root.resourceValues(forKeys: [.canonicalPathKey]))?.canonicalPath
        let paths = [path, canonicalPath ?? path].map { $0.hasSuffix("/") ? $0 : $0 + "/" }
        return paths[0] == paths[1] ? [paths[0]] : paths
    }
}
