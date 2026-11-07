import Foundation

/// Finds the volume that holds a file or folder.
public protocol VolumeResolving: Sendable {
    /// The root of the volume containing the item, or nil if it cannot be determined.
    func volume(containing url: URL) -> URL?
}
