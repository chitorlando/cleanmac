import Foundation

/// One of the folders that make up the user's Trash: the one in the home folder, or the one
/// macOS keeps for the user on each other volume, such as an external disk.
public struct TrashBin: Hashable, Sendable {
    public let url: URL
    /// The volume the bin is on, such as “Backup Disk”, or `nil` for the bin in the home folder.
    public let volumeName: String?

    public init(url: URL, volumeName: String? = nil) {
        self.url = url
        self.volumeName = volumeName
    }
}

/// How much a Trash bin holds.
public struct TrashBinUsage: Hashable, Sendable {
    public let bin: TrashBin
    /// Bytes allocated on disk to what the bin holds, which emptying it frees.
    public let size: Int64

    public init(bin: TrashBin, size: Int64) {
        self.bin = bin
        self.size = size
    }
}

/// What CleanMac can tell about the user's Trash.
public enum TrashUsage: Equatable, Sendable {
    /// The bins that hold something, the one in the home folder first.
    case readable([TrashBinUsage])
    /// macOS keeps CleanMac out of the Trash until it has Full Disk Access, so its size is unknown.
    case unreadable
}
