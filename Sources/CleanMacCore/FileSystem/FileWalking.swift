import Foundation

/// Visits the regular files under a folder.
public protocol FileWalking: Sendable {
    /// Calls `visit` for each file under `root`. Walking stops as soon as `visit` returns `false`.
    func walk(_ root: URL, visit: (FileRecord) -> Bool)
}
