import Foundation

/// Facts about this Mac that decide what some maintenance commands act on.
public struct MaintenanceEnvironment: Equatable, Sendable {
    /// Volumes whose Spotlight index gets rebuilt, without duplicates.
    public let spotlightVolumes: [URL]

    public init(spotlightVolumes: [URL]) {
        self.spotlightVolumes = spotlightVolumes
    }
}
