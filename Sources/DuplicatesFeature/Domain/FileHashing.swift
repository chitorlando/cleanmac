import Foundation

/// Computes a digest of a file's contents.
public protocol FileHashing: Sendable {
    /// Hashes the first `limit` bytes of the file, or all of it when `limit` is `nil`.
    /// Throws when the file can't be read or the task is cancelled.
    func hash(of url: URL, upTo limit: Int64?) throws -> FileHash
}
