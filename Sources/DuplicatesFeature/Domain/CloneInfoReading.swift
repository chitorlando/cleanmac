import Foundation

/// Reads what a file's volume reports about the data the file shares with its clones.
public protocol CloneInfoReading: Sendable {
    /// Returns `nil` when the file can't be inspected or its volume doesn't track clones.
    func cloneInfo(of url: URL) -> CloneInfo?
}
