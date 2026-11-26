import CleanMacCore
import Foundation

/// A folder of the disk map while the walk is still filling it.
///
/// A walk of the home folder finds millions of files, so until the map is built a file that
/// may be shown keeps only its name, size and kind. Its URL is made when the map is built,
/// and only if the map shows it.
final class FolderAccumulator {
    /// A file or package directly inside the folder, kept as small as it can be.
    private struct Leaf {
        let name: String
        let size: Int64
        let isPackage: Bool
    }

    let url: URL
    private var subfolders: [String: FolderAccumulator] = [:]
    /// Files and packages that may be large enough to show on their own.
    private var leaves: [Leaf] = []
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

    /// Adds the file or package of `record`, named `name`, directly inside the folder.
    func add(_ record: FileRecord, named name: String, grouping: SmallItemGrouping) {
        let leaf = Leaf(name: name, size: record.size, isPackage: record.isPackage)
        directSize += leaf.size
        if grouping.isSmall(leaf.size, inFolderOf: directSize) {
            smallLeaves.add(size: leaf.size, fileCount: 1) { node(for: leaf) }
        } else {
            leaves.append(leaf)
        }
    }

    /// The finished folder: sizes added up, small items counted together and the rest largest first.
    ///
    /// An item that is or holds a folder that couldn't be read stays in sight however small it
    /// is, so the user can find what the map is missing.
    func node(grouping: SmallItemGrouping) -> DiskNode {
        // Naming and sorting the items makes temporary Foundation objects, which would
        // otherwise pile up until the whole map is built: hundreds of megabytes for a home
        // folder with a million files.
        autoreleasepool { finishedNode(grouping: grouping) }
    }

    private func finishedNode(grouping: SmallItemGrouping) -> DiskNode {
        let leafSize = leaves.reduce(smallLeaves.size) { $0 + $1.size }
        let subfolderNodes = subfolders.values.map { $0.node(grouping: grouping) }
        let size = subfolderNodes.reduce(leafSize) { $0 + $1.size }
        let fileCount = subfolderNodes.reduce(smallLeaves.fileCount + leaves.count) { $0 + $1.fileCount }

        var small = smallLeaves
        var shown: [DiskNode] = []
        for item in subfolderNodes {
            if item.unreadableFolderCount == 0, grouping.isSmall(item.size, inFolderOf: size) {
                small.add(item)
            } else {
                shown.append(item)
            }
        }
        for leaf in leaves {
            if grouping.isSmall(leaf.size, inFolderOf: size) {
                small.add(size: leaf.size, fileCount: 1) { node(for: leaf) }
            } else {
                shown.append(node(for: leaf))
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

    private func node(for leaf: Leaf) -> DiskNode {
        DiskNode(
            url: url.appending(path: leaf.name, directoryHint: leaf.isPackage ? .isDirectory : .notDirectory),
            kind: leaf.isPackage ? .package : .file,
            size: leaf.size,
            fileCount: 1
        )
    }
}
