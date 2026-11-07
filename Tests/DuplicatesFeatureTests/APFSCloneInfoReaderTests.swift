import Darwin
import DuplicatesFeature
import Foundation
import Testing

/// Runs on real clones made with `clonefile(2)` in the temporary folder, which is on APFS.
struct APFSCloneInfoReaderTests {
    private let reader = APFSCloneInfoReader()
    private let content = Data.pattern(count: 200_000, seed: 4)

    private func info(_ url: URL) throws -> CloneInfo {
        try #require(reader.cloneInfo(of: url))
    }

    @Test func clonesShareTheirDataStream() throws {
        let folder = try TemporaryFolder()
        let original = try folder.write(content, to: "original.bin")
        let clone = try folder.makeClone("Copies/clone.bin", of: original)
        let cloneOfClone = try folder.makeClone("clone of clone.bin", of: clone)

        let infos = try [original, clone, cloneOfClone].map(info)

        #expect(Set(infos.map(\.streamID)).count == 1)
        #expect(infos.allSatisfy { $0.cloneCount == 3 })
        #expect(infos.allSatisfy { !$0.mayShareSomeData })
    }

    @Test func independentCopiesKeepTheirOwnData() throws {
        let folder = try TemporaryFolder()
        let first = try info(folder.write(content, to: "first.bin"))
        let second = try info(folder.write(content, to: "second.bin"))

        #expect(first.streamID != second.streamID)
        #expect(first.cloneCount == 1)
        #expect(second.cloneCount == 1)
        #expect(!first.mayShareSomeData)
        #expect(!second.mayShareSomeData)
    }

    @Test func aModifiedCloneGetsItsOwnStreamButMayStillShareData() throws {
        let folder = try TemporaryFolder()
        let original = try folder.write(content, to: "original.bin")
        let clone = try folder.makeClone("clone.bin", of: original)

        try folder.overwriteStart(of: clone, with: Data([0xFF]))

        let originalInfo = try info(original)
        let cloneInfo = try info(clone)
        #expect(originalInfo.streamID != cloneInfo.streamID)
        #expect(originalInfo.cloneCount == 1)
        #expect(cloneInfo.cloneCount == 1)
        #expect(originalInfo.mayShareSomeData)
        #expect(cloneInfo.mayShareSomeData)
    }

    @Test func identifiesTheVolumeOfTheData() throws {
        let folder = try TemporaryFolder()
        let url = try folder.write(content, to: "file.bin")
        var status = stat()
        try #require(lstat(url.path, &status) == 0)

        #expect(try info(url).streamID.device == Int64(status.st_dev))
    }

    @Test func returnsNothingForMissingFiles() {
        let missing = URL(filePath: "/nonexistent/\(UUID().uuidString)")

        #expect(reader.cloneInfo(of: missing) == nil)
    }
}
