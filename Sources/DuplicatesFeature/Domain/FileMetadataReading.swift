import Foundation

/// Reads the identity and creation date of a file.
public protocol FileMetadataReading: Sendable {
    /// Returns `nil` when the file can't be inspected.
    func metadata(of url: URL) -> FileMetadata?
}
