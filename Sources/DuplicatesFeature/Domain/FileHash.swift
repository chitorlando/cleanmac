import Foundation

/// Digest of a file's contents, or of its first bytes, and how many bytes were read to compute it.
public struct FileHash: Hashable, Sendable {
    public let digest: Data
    public let bytesRead: Int64

    public init(digest: Data, bytesRead: Int64) {
        self.digest = digest
        self.bytesRead = bytesRead
    }

    /// Lowercase hexadecimal form of the digest.
    public var hexDigest: String {
        digest.map { String(format: "%02x", $0) }.joined()
    }
}
