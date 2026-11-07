import Foundation

/// An item of the Library that may belong to an app, together with the folder it was found in.
public struct LeftoverCandidate: Hashable, Sendable {
    public let url: URL
    public let location: LeftoverLocation

    public init(url: URL, location: LeftoverLocation) {
        self.url = url
        self.location = location
    }
}
