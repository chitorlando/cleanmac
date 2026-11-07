import CleanMacCore
import Foundation

/// The direct children of every leftover location, listed once and shared by all apps.
public struct LibrarySnapshot: Sendable {
    public let candidates: [LeftoverCandidate]

    public init(locations: [LeftoverLocation], reader: any DirectoryReading) {
        candidates = locations
            .filter { reader.itemExists(at: $0.url) }
            .flatMap { location in
                ((try? reader.childItems(of: location.url)) ?? [])
                    .map { LeftoverCandidate(url: $0, location: location) }
            }
    }
}
