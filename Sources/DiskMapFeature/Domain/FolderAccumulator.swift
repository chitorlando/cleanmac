import Foundation

/// A folder of the disk map while the walk is still filling it.
final class FolderAccumulator {
    let url: URL
    private var subfolders: [String: FolderAccumulator] = [:]
    /// Files and packages that may be large enough to show on their own.
    private var leaves: [DiskNode] = []
    /// Files and packages already known to be small, counted together.
    private var smallLeaves = SmallItemPile()
    /// Bytes of the files and packages directly inside. The folder ends up at least this
    /// large, so a file that is small next to them stays small until the end.
    private var directSize: Int64 = 0

    init(url: URL) {
        self.url = url
    }

    func subfolder(named name: String) -> FolderAccumulator {
        if let folder = subfolders[name] {
            return folder
        }
        let folder = FolderAccumulator(url: url.appending(path: name, directoryHint: .isDirectory))
        subfolders[name] = folder
        return folder
    }

    /// Adds a file or package directly inside the folder.
    func add(_ leaf: DiskNode, grouping: SmallItemGrouping) {
        directSize += leaf.size
        if grouping.isSmall(leaf.size, inFolderOf: directSize) {
            smallLeaves.add(leaf)
        } else {
            leaves.append(leaf)
        }
    }

    /// The finished folder: sizes added up, small items counted together and the rest largest first.
    func node(grouping: SmallItemGrouping) -> DiskNode {
        let items = subfolders.values.map { $0.node(grouping: grouping) } + leaves
        let size = items.reduce(smallLeaves.size) { $0 + $1.size }
        let fileCount = items.reduce(smallLeaves.fileCount) { $0 + $1.fileCount }

        var small = smallLeaves
        var shown: [DiskNode] = []
        for item in items {
            if grouping.isSmall(item.size, inFolderOf: size) {
                small.add(item)
            } else {
                shown.append(item)
            }
        }
        if let loneItem = small.loneItem {
            shown.append(loneItem)
        }

        return DiskNode(
            url: url,
            kind: .folder,
            size: size,
            fileCount: fileCount,
            children: shown.sorted(by: DiskNode.isLarger),
            otherItems: small.otherItems
        )
    }
}
