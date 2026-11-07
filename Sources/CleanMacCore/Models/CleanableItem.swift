import Foundation

/// A file or folder that can be safely removed, together with the disk space it occupies.
public struct CleanableItem: Identifiable, Hashable, Sendable {
    public let url: URL
    public let size: Int64

    public var id: URL { url }
    public var name: String { url.lastPathComponent }

    public init(url: URL, size: Int64) {
        self.url = url
        self.size = size
    }
}

public extension Sequence where Element == CleanableItem {
    /// Combined size in bytes of every item in the sequence.
    var totalSize: Int64 { reduce(0) { $0 + $1.size } }
}
