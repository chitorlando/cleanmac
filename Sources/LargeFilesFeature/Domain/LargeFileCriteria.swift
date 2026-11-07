import Foundation

/// Which files count as large or old enough to be worth reviewing.
public struct LargeFileCriteria: Sendable {
    public static let defaultMinimumSize: Int64 = 50 * ByteSize.megabyte

    /// Smallest size, in bytes, a file must have.
    public let minimumSize: Int64
    /// When set, only files last used before this date match.
    /// Files with no known date never match, since they can't be shown to be old.
    public let olderThan: Date?

    public init(minimumSize: Int64 = defaultMinimumSize, olderThan: Date? = nil) {
        self.minimumSize = minimumSize
        self.olderThan = olderThan
    }

    public func matches(_ record: FileRecord) -> Bool {
        guard record.size >= minimumSize else { return false }
        guard let olderThan else { return true }
        guard let lastAccessDate = record.lastAccessDate else { return false }
        return lastAccessDate < olderThan
    }
}
