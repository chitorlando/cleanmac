import Foundation

/// Measures how much disk space a file or folder occupies.
public protocol SizeCalculating: Sendable {
    /// Size in bytes. Unreadable items count as zero.
    func size(of url: URL) -> Int64
}
