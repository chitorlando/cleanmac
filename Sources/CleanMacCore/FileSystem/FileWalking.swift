import Foundation

/// Visits the regular files under a folder.
public protocol FileWalking: Sendable {
    /// Calls `visit` for each file under `root`. Walking stops as soon as `visit` returns `false`.
    func walk(_ root: URL, visit: (FileRecord) -> Bool)

    /// Walks like `walk(_:visit:)`, and also calls `unreadable` with each folder it couldn't
    /// look into, `root` included, such as one that macOS keeps private. What such a folder
    /// holds is left out of the walk.
    func walk(_ root: URL, visit: (FileRecord) -> Bool, unreadable: (URL) -> Void)
}

public extension FileWalking {
    /// Walkers that never find a folder they can't read report none.
    func walk(_ root: URL, visit: (FileRecord) -> Bool, unreadable: (URL) -> Void) {
        walk(root, visit: visit)
    }
}
