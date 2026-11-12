import Foundation
import MonitorFeature
import Testing

struct VolumeCapacityTests {
    private let startup = VolumeCapacity(url: URL(filePath: "/"), name: "Macintosh HD", totalBytes: 1_000, availableBytes: 250)
    private let data = VolumeCapacity(url: URL(filePath: "/Volumes/Data"), name: "Data", totalBytes: 4_000, availableBytes: 3_000)

    @Test func derivesTheUsedSpace() {
        #expect(startup.usedBytes == 750)
        #expect(startup.usedFraction == 0.75)
    }

    @Test func neverReportsMoreThanTheWholeVolume() {
        let odd = VolumeCapacity(url: URL(filePath: "/"), name: "Odd", totalBytes: 100, availableBytes: 150)

        #expect(odd.usedBytes == 0)
        #expect(odd.usedFraction == 0)
    }

    @Test func listsEachVolumeOnce() {
        let reader = FakeVolumeReader(volumes: ["/Volumes/Data": data, "/": startup])

        let volumes = reader.capacities(ofVolumesHolding: [URL(filePath: "/"), URL(filePath: "/Volumes/Data/Users/me"), URL(filePath: "/Applications")])

        #expect(volumes == [startup, data])
    }

    @Test func skipsVolumesThatCannotBeRead() {
        let reader = FakeVolumeReader(volumes: [:])

        #expect(reader.capacities(ofVolumesHolding: [URL(filePath: "/")]).isEmpty)
    }

    @Test func readsTheStartupVolume() throws {
        let volume = try #require(LocalVolumeCapacityReader().capacity(ofVolumeHolding: URL(filePath: "/")))

        #expect(volume.totalBytes > 0)
        #expect(volume.availableBytes <= volume.totalBytes)
    }
}
