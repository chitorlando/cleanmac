import CleanMacCore
import Foundation

/// Builds the `MaintenanceEnvironment` of this Mac from the file system.
public struct MaintenanceEnvironmentReader: Sendable {
    private let volumes: any VolumeResolving
    private let homeDirectory: URL
    private let bootVolume: URL

    public init(
        volumes: any VolumeResolving = LocalVolumeResolver(),
        homeDirectory: URL = .homeDirectory,
        bootVolume: URL = URL(filePath: "/")
    ) {
        self.volumes = volumes
        self.homeDirectory = homeDirectory
        self.bootVolume = bootVolume
    }

    /// Spotlight covers the startup volume and, when the home folder lives elsewhere, its volume too.
    /// Other volumes, such as external or backup disks, are left alone.
    public func read() -> MaintenanceEnvironment {
        let startup = volumes.volume(containing: bootVolume) ?? bootVolume
        let candidates = [startup, volumes.volume(containing: homeDirectory)].compactMap(\.self)
        var seenPaths = Set<String>()
        let unique = candidates.filter { seenPaths.insert($0.standardizedFileURL.path).inserted }
        return MaintenanceEnvironment(spotlightVolumes: unique)
    }
}
