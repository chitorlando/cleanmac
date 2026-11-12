import Foundation
import MonitorFeature

/// Answers with the volume of the deepest known folder that holds the item.
struct FakeVolumeReader: VolumeCapacityReading {
    let volumes: [String: VolumeCapacity]

    func capacity(ofVolumeHolding url: URL) -> VolumeCapacity? {
        volumes.filter { url.path.hasPrefix($0.key) }.max { $0.key.count < $1.key.count }?.value
    }
}
