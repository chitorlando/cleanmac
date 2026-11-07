import CleanMacCore
import Foundation

/// Answers with predefined volumes, keyed by item path.
struct FakeVolumeResolver: VolumeResolving {
    let volumes: [String: URL]

    func volume(containing url: URL) -> URL? { volumes[url.path] }
}
