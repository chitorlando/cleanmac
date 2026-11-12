import Foundation

/// Reads the space of the volume that holds a file or folder.
public protocol VolumeCapacityReading: Sendable {
    /// The volume holding `url`, or `nil` when it can't be read.
    func capacity(ofVolumeHolding url: URL) -> VolumeCapacity?
}

public extension VolumeCapacityReading {
    /// The volumes holding `urls`, each one once, in the order of the first item it holds.
    func capacities(ofVolumesHolding urls: [URL]) -> [VolumeCapacity] {
        var seen: Set<URL> = []
        return urls.compactMap { url in
            guard let volume = capacity(ofVolumeHolding: url), seen.insert(volume.url).inserted else { return nil }
            return volume
        }
    }
}
