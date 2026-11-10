import DiskMapFeature
import Foundation

/// Small maps of a home folder at `/Users/test`, built by hand.
enum DiskMapFixtures {
    static let home = URL(filePath: "/Users/test")

    static func file(_ path: String, _ size: Int64, kind: DiskNodeKind = .file) -> DiskNode {
        DiskNode(url: home.appending(path: path), kind: kind, size: size, fileCount: 1)
    }

    /// A folder whose size and file count add up its items, which must be given largest first.
    static func folder(_ path: String, _ children: [DiskNode], other: OtherItems? = nil) -> DiskNode {
        DiskNode(
            url: path.isEmpty ? home : home.appending(path: path),
            kind: .folder,
            size: children.reduce(other?.size ?? 0) { $0 + $1.size },
            fileCount: children.reduce(other?.fileCount ?? 0) { $0 + $1.fileCount },
            children: children,
            otherItems: other
        )
    }

    /// Home with movies, a cache, the user's mail and an app.
    static var map: DiskNode {
        folder("", [
            folder("Movies", [
                folder("Movies/Trips", [file("Movies/Trips/beach.mov", 400)]),
                file("Movies/clip.mov", 100)
            ]),
            folder("Library", [
                folder("Library/Caches", [folder("Library/Caches/com.example", [file("Library/Caches/com.example/data", 150)])]),
                folder("Library/Mail", [file("Library/Mail/inbox.mbox", 100)])
            ]),
            file("Applications/Tool.app", 120, kind: .package),
            file("notes.txt", 30)
        ], other: OtherItems(itemCount: 3, size: 6, fileCount: 3))
    }
}
