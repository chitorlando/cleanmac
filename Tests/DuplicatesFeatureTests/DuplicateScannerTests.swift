import CleanMacCore
import DuplicatesFeature
import Foundation
import Testing

struct DuplicateScannerTests {
    private static let fileSize = 200_000

    private func scan(
        _ folder: TemporaryFolder,
        minimumSize: Int64 = 100_000,
        cloneInfoReader: any CloneInfoReading = APFSCloneInfoReader()
    ) async -> [DuplicateScanEvent] {
        let scanner = DuplicateScanner(
            root: folder.root,
            walker: FileSystemWalker(excludedDirectories: []),
            cloneInfoReader: cloneInfoReader,
            minimumSize: minimumSize
        )
        var events: [DuplicateScanEvent] = []
        for await event in scanner.scan() {
            events.append(event)
        }
        return events
    }

    private func groups(_ events: [DuplicateScanEvent]) -> [DuplicateGroup] {
        events.compactMap { event in
            if case .found(let group) = event { group } else { nil }
        }
    }

    @Test func groupsIdenticalFiles() async throws {
        let folder = try TemporaryFolder()
        let content = Data.pattern(count: Self.fileSize, seed: 1)
        try folder.write(content, to: "Documents/report.pdf")
        try folder.write(content, to: "Downloads/report.pdf")
        try folder.write(content, to: "Desktop/report copy.pdf")
        try folder.write(Data.pattern(count: Self.fileSize, seed: 2), to: "Documents/other.pdf")

        let found = groups(await scan(folder))

        #expect(found.count == 1)
        let group = try #require(found.first)
        #expect(Set(group.files.map(\.item.name)) == ["report.pdf", "report copy.pdf"])
        #expect(group.files.count == 3)
        #expect(group.recoverableSize == group.fileSize * 2)
        #expect(group.files.allSatisfy { $0.creationDate != nil })
    }

    @Test func ignoresFilesOfTheSameSizeWithDifferentContents() async throws {
        let folder = try TemporaryFolder()
        try folder.write(Data.pattern(count: Self.fileSize, seed: 1), to: "a.bin")
        try folder.write(Data.pattern(count: Self.fileSize, seed: 2), to: "b.bin")

        #expect(groups(await scan(folder)).isEmpty)
    }

    @Test func ignoresFilesThatOnlyShareTheirBeginning() async throws {
        let folder = try TemporaryFolder()
        var original = Data.pattern(count: Self.fileSize, seed: 1)
        try folder.write(original, to: "a.bin")
        original[Self.fileSize - 1] ^= 0xFF
        try folder.write(original, to: "b.bin")

        #expect(groups(await scan(folder)).isEmpty)
    }

    @Test func ignoresFilesBelowTheMinimumSize() async throws {
        let folder = try TemporaryFolder()
        let content = Data.pattern(count: 1_000, seed: 1)
        try folder.write(content, to: "a.txt")
        try folder.write(content, to: "b.txt")

        #expect(groups(await scan(folder, minimumSize: DuplicateScanner.defaultMinimumSize)).isEmpty)
    }

    @Test func doesNotReportHardLinksAsCopies() async throws {
        let folder = try TemporaryFolder()
        let original = try folder.write(Data.pattern(count: Self.fileSize, seed: 1), to: "a.bin")
        try folder.makeHardLink("link.bin", to: original)

        #expect(groups(await scan(folder)).isEmpty)
    }

    @Test func tellsWhichCopiesHaveOtherNames() async throws {
        let folder = try TemporaryFolder()
        let content = Data.pattern(count: Self.fileSize, seed: 1)
        let linked = try folder.write(content, to: "Documents/report.pdf")
        // A hidden name, which the walk skips like any hidden file.
        try folder.makeHardLink(".report.pdf", to: linked)
        try folder.write(content, to: "Downloads/report.pdf")

        let group = try #require(groups(await scan(folder)).first)

        #expect(group.files.count == 2)
        let linkedFolders = group.files.filter(\.hasOtherNames).map { $0.item.url.deletingLastPathComponent().lastPathComponent }
        #expect(linkedFolders == ["Documents"])
    }

    @Test func promisesNoSpaceForAFileWithANameTheScanSkips() async throws {
        let folder = try TemporaryFolder()
        let content = Data.pattern(count: Self.fileSize, seed: 1)
        let linked = try folder.write(content, to: "Documents/report.pdf")
        try folder.makeHardLink(".report.pdf", to: linked)
        try folder.write(content, to: "Downloads/report.pdf")

        let group = try #require(groups(await scan(folder)).first)
        let linkedCopy = try #require(group.files.first { $0.hasOtherNames })

        #expect(group.physicalCopy(containing: linkedCopy)?.freeableSize == 0)
        #expect(group.recoverableSize == group.fileSize)
        #expect(DuplicateKeeper.keeper(in: group) == linkedCopy)
    }

    @Test func promisesNoSpaceForAFileWithTwoScannedNames() async throws {
        let folder = try TemporaryFolder()
        let content = Data.pattern(count: Self.fileSize, seed: 1)
        let linked = try folder.write(content, to: "Documents/report.pdf")
        try folder.makeHardLink("report link.pdf", to: linked)
        try folder.write(content, to: "Downloads/report.pdf")

        let group = try #require(groups(await scan(folder)).first)
        let linkedCopy = try #require(group.files.first { $0.hasOtherNames })

        #expect(group.files.count == 2)
        #expect(group.physicalCopy(containing: linkedCopy)?.freeableSize == 0)
        #expect(group.recoverableSize == group.fileSize)
    }

    @Test func countsClonesOfEachOtherAsOnePhysicalCopy() async throws {
        let folder = try TemporaryFolder()
        let content = Data.pattern(count: Self.fileSize, seed: 1)
        let original = try folder.write(content, to: "Documents/photo.heic")
        try folder.makeClone("Desktop/photo.heic", of: original)
        try folder.write(content, to: "Downloads/photo.heic")

        let group = try #require(groups(await scan(folder)).first)

        #expect(group.files.count == 3)
        #expect(group.physicalCopies.count == 2)
        #expect(group.recoverableSize == group.fileSize)
        let clonedFolders = group.files.filter(\.isClone).map { $0.item.url.deletingLastPathComponent().lastPathComponent }
        #expect(Set(clonedFolders) == ["Documents", "Desktop"])
    }

    @Test func doesNotCountSpaceWhenTheVolumeCannotTellHowDataIsShared() async throws {
        let folder = try TemporaryFolder()
        let content = Data.pattern(count: Self.fileSize, seed: 1)
        try folder.write(content, to: "a.bin")
        try folder.write(content, to: "b.bin")

        let group = try #require(groups(await scan(folder, cloneInfoReader: StubCloneInfoReader())).first)

        #expect(group.files.count == 2)
        #expect(group.files.allSatisfy { $0.cloneInfo == nil })
        #expect(group.recoverableSize == 0)
    }

    @Test func reportsScannedFilesAndHashedBytes() async throws {
        let folder = try TemporaryFolder()
        let content = Data.pattern(count: Self.fileSize, seed: 1)
        try folder.write(content, to: "a.bin")
        try folder.write(content, to: "b.bin")
        try folder.write(Data.pattern(count: 10, seed: 1), to: "small.txt")

        let progress = await scan(folder).compactMap { event in
            if case .progress(let progress) = event { progress } else { nil }
        }

        let last = try #require(progress.last)
        #expect(last.scannedFiles == 3)
        // Two partial hashes of 64 KB, then two full hashes.
        #expect(last.hashedBytes == 2 * 65_536 + 2 * Int64(Self.fileSize))
    }

    @Test(.timeLimit(.minutes(1)))
    func stopsWalkingWhenTheConsumerStopsListening() async {
        let walker = EndlessWalker()
        let scanner = DuplicateScanner(root: URL(filePath: "/tmp"), walker: walker, progressInterval: 1)

        for await _ in scanner.scan() {
            break
        }

        for await _ in walker.finished {}
    }
}
