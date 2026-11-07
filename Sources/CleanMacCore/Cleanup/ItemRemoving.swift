import Foundation

/// Strategy that removes a single item from disk.
public protocol ItemRemoving: Sendable {
    func remove(_ url: URL) async throws
}
