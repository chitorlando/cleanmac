import Foundation

/// `VolumeCapacityReading` from the file system's volume metadata.
public struct LocalVolumeCapacityReader: VolumeCapacityReading {
    private static let keys: Set<URLResourceKey> = [
        .volumeURLKey,
        .volumeLocalizedNameKey,
        .volumeTotalCapacityKey,
        .volumeAvailableCapacityForImportantUsageKey
    ]

    public init() {}

    public func capacity(ofVolumeHolding url: URL) -> VolumeCapacity? {
        guard
            let values = try? url.resourceValues(forKeys: Self.keys),
            let volume = values.volume,
            let total = values.volumeTotalCapacity,
            let available = values.volumeAvailableCapacityForImportantUsage
        else { return nil }
        return VolumeCapacity(
            url: volume,
            name: values.volumeLocalizedName ?? volume.lastPathComponent,
            totalBytes: Int64(total),
            availableBytes: available
        )
    }
}
