import DuplicatesFeature
import Foundation

/// Reports the clone information given for each file, and nothing for the rest.
struct StubCloneInfoReader: CloneInfoReading {
    var infos: [URL: CloneInfo] = [:]

    func cloneInfo(of url: URL) -> CloneInfo? {
        infos[url]
    }
}
