import Foundation

/// `VolumeResolving` backed by the file system's volume metadata.
public struct LocalVolumeResolver: VolumeResolving {
    public init() {}

    public func volume(containing url: URL) -> URL? {
        try? url.resourceValues(forKeys: [.volumeURLKey]).volume
    }
}
