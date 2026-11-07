@testable import MaintenanceFeature
import Foundation
import Testing

struct MaintenanceEnvironmentReaderTests {
    private let root = URL(filePath: "/")
    private let home = URL(filePath: "/Users/someone")
    private let dataVolume = URL(filePath: "/Volumes/MacData/")

    private func spotlightVolumes(_ volumes: [String: URL]) -> [String] {
        MaintenanceEnvironmentReader(
            volumes: FakeVolumeResolver(volumes: volumes),
            homeDirectory: home,
            bootVolume: root
        ).read().spotlightVolumes.map(\.path)
    }

    @Test func usesOneVolumeWhenHomeIsOnTheStartupDisk() {
        #expect(spotlightVolumes(["/": root, home.path: root]) == ["/"])
    }

    @Test func addsTheVolumeThatHoldsHome() {
        #expect(spotlightVolumes(["/": root, home.path: dataVolume]) == ["/", "/Volumes/MacData"])
    }

    @Test func ignoresTrailingSlashDifferences() {
        #expect(spotlightVolumes(["/": URL(filePath: "/"), home.path: URL(filePath: "/", directoryHint: .isDirectory)]) == ["/"])
    }

    @Test func fallsBackToTheStartupVolumeWhenNothingResolves() {
        #expect(spotlightVolumes([:]) == ["/"])
    }
}
