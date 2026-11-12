import Foundation

/// Space on a volume, such as the startup disk.
public struct VolumeCapacity: Identifiable, Equatable, Sendable {
    /// Root of the volume.
    public let url: URL
    public let name: String
    public let totalBytes: Int64
    /// Space available for things the user wants to keep, which counts space macOS can free
    /// by removing purgeable files, as Finder does.
    public let availableBytes: Int64

    public init(url: URL, name: String, totalBytes: Int64, availableBytes: Int64) {
        self.url = url
        self.name = name
        self.totalBytes = totalBytes
        self.availableBytes = availableBytes
    }

    public var id: URL { url }

    public var usedBytes: Int64 { max(totalBytes - availableBytes, 0) }

    /// Share of the volume in use, from 0 to 1.
    public var usedFraction: Double {
        totalBytes > 0 ? min(Double(usedBytes) / Double(totalBytes), 1) : 0
    }
}
