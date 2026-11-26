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
    /// The walk couldn't look inside the folder.
    private var isUnreadable = false

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

    /// Marks the folder as one the walk couldn't look into.
    func markUnreadable() {
        isUnreadable = true
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
    ///
    /// An item that is or holds a folder that couldn't be read stays in sight however small it
    /// is, so the user can find what the map is missing.
    func node(grouping: SmallItemGrouping) -> DiskNode {
        let items = subfolders.values.map { $0.node(grouping: grouping) } + leaves
        let size = items.reduce(smallLeaves.size) { $0 + $1.size }
        let fileCount = items.reduce(smallLeaves.fileCount) { $0 + $1.fileCount }

        var small = smallLeaves
        var shown: [DiskNode] = []
        for item in items {
            if item.unreadableFolderCount == 0, grouping.isSmall(item.size, inFolderOf: size) {
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
            otherItems: small.otherItems,
            isUnreadable: isUnreadable
        )
    }
}
