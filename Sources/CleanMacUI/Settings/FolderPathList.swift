import Foundation

/// The paths of the folders in a list: each once, in the order they were added.
struct FolderPathList: Equatable, Sendable {
    private(set) var paths: [String] = []

    /// - Parameter paths: Kept in their order, each once.
    init(_ paths: [String]) {
        for path in paths where !self.paths.contains(path) {
            self.paths.append(path)
        }
    }

    /// Adds `folders` at the end, each spelled the way `folderToAdd` gives it, except those
    /// already in the list.
    ///
    /// - Parameter folderToAdd: The folder to add for one that was chosen, which may spell it
    ///   another way, or `nil` when the list doesn't take it.
    /// - Returns: The folders `folderToAdd` didn't take, in the order they came.
    @discardableResult
    mutating func add(_ folders: [URL], as folderToAdd: (URL) -> URL?) -> [URL] {
        var refused: [URL] = []
        for folder in folders {
            guard let path = folderToAdd(folder)?.path else {
                refused.append(folder)
                continue
            }
            if !paths.contains(path) {
                paths.append(path)
            }
        }
        return refused
    }

    mutating func remove(_ path: String) {
        paths.removeAll { $0 == path }
    }
}
