import CleanMacCore
import DiskMapFeature
import Foundation
import Testing

struct DiskMapScannerTests {
    private let root = URL(filePath: "/Users/test")

    private func events(of scanner: DiskMapScanner) async -> [DiskMapScanEvent] {
        var events: [DiskMapScanEvent] = []
        for await event in scanner.scan() {
            events.append(event)
        }
        return events
    }

    private func map(of scanner: DiskMapScanner) async throws -> DiskNode {
        let maps = await events(of: scanner).compactMap { event in
            if case .finished(let map) = event { map } else { nil }
        }
        #expect(maps.count == 1)
        return try #require(maps.first)
    }

    /// Scans a folder on disk with the walker the disk map uses, packages measured whole.
    private func map(of folder: TemporaryFolder, minimumShare: Double = 0) async throws -> DiskNode {
        let scanner = DiskMapScanner(
            root: folder.root,
            walker: FileSystemWalker(excludedDirectories: [], packageSizeCalculator: AllocatedSizeCalculator()),
            grouping: SmallItemGrouping(minimumShare: minimumShare)
        )
        return try await map(of: scanner)
    }

    private func child(_ name: String, of node: DiskNode) throws -> DiskNode {
        try #require(node.children.first { $0.name == name })
    }

    // MARK: Folders on disk

    @Test func addsUpTheSpaceOfEveryFolderOnDisk() async throws {
        let folder = try TemporaryFolder()
        try folder.makeFile("Movies/Trips/beach.mov", size: 400_000)
        try folder.makeFile("Movies/clip.mov", size: 100_000)
        try folder.makeFile("Documents/report.pdf", size: 50_000)

        let map = try await map(of: folder)
        let movies = try child("Movies", of: map)

        #expect(map.url == folder.root)
        #expect(map.size == (try folder.allocatedSize(of: "Movies/Trips/beach.mov", "Movies/clip.mov", "Documents/report.pdf")))
        #expect(map.fileCount == 3)
        #expect(movies.size == (try folder.allocatedSize(of: "Movies/Trips/beach.mov", "Movies/clip.mov")))
        #expect(movies.fileCount == 2)
    }

    @Test func listsTheLargestItemsFirst() async throws {
        let folder = try TemporaryFolder()
        try folder.makeFile("Documents/report.pdf", size: 50_000)
        try folder.makeFile("Movies/clip.mov", size: 100_000)
        try folder.makeFile("Movies/Trips/beach.mov", size: 400_000)
        try folder.makeFile("notes.txt", size: 70_000)

        let map = try await map(of: folder)

        #expect(map.children.map(\.name) == ["Movies", "notes.txt", "Documents"])
        #expect(try child("Movies", of: map).children.map(\.name) == ["Trips", "clip.mov"])
    }

    @Test func countsSmallItemsOnDiskTogether() async throws {
        let folder = try TemporaryFolder()
        try folder.makeFile("big.bin", size: 2_000_000)
        try folder.makeFile("a.txt")
        try folder.makeFile("b.txt")
        try folder.makeFile("Notes/c.txt")

        let map = try await map(of: folder, minimumShare: SmallItemGrouping.defaultMinimumShare)

        #expect(map.children.map(\.name) == ["big.bin"])
        #expect(map.otherItems?.itemCount == 3)
        #expect(map.otherItems?.fileCount == 3)
        #expect(map.otherItems?.size == (try folder.allocatedSize(of: "a.txt", "b.txt", "Notes/c.txt")))
    }

    @Test func measuresPackagesWholeWithoutEnteringThem() async throws {
        let folder = try TemporaryFolder()
        try folder.makeFile("Applications/Tool.app/Contents/MacOS/Tool", size: 200_000)
        try folder.makeFile("Applications/Tool.app/Contents/Resources/big.bin", size: 300_000)
        try folder.makeFile("notes.txt")

        let map = try await map(of: folder)
        let tool = try child("Tool.app", of: child("Applications", of: map))

        #expect(tool.kind == .package)
        #expect(tool.children.isEmpty)
        #expect(tool.fileCount == 1)
        #expect(tool.size == (try folder.allocatedSize(
            of: "Applications/Tool.app/Contents/MacOS/Tool",
            "Applications/Tool.app/Contents/Resources/big.bin"
        )))
        #expect(map.fileCount == 2)
    }

    @Test func leavesHiddenItemsOut() async throws {
        let folder = try TemporaryFolder()
        try folder.makeFile(".cache/big.bin", size: 500_000)
        try folder.makeFile("visible.txt")

        let map = try await map(of: folder)

        #expect(map.children.map(\.name) == ["visible.txt"])
    }

    // MARK: Progress

    @Test func reportsFilesAndBytesEveryIntervalAndAtTheEnd() async {
        let scanner = DiskMapScanner(
            root: root,
            walker: StubWalker(root: root, sizes: [10, 20, 30, 40, 50, 60, 70]),
            progressInterval: 3
        )

        let progress = await events(of: scanner).compactMap { event in
            if case .progress(let progress) = event { progress } else { nil }
        }

        #expect(progress == [
            DiskMapProgress(fileCount: 3, byteCount: 60),
            DiskMapProgress(fileCount: 6, byteCount: 210),
            DiskMapProgress(fileCount: 7, byteCount: 280)
        ])
    }

    @Test func endsWithTheMapAfterTheLastProgress() async throws {
        let scanner = DiskMapScanner(root: root, walker: StubWalker(root: root, sizes: [10, 20, 30]), progressInterval: 3)

        let events = await events(of: scanner)

        #expect(events.count == 2)
        #expect(events.first == .progress(DiskMapProgress(fileCount: 3, byteCount: 60)))
        let map = try await map(of: scanner)
        #expect(events.last == .finished(map))
        #expect(map.size == 60)
    }

    @Test func mapsAnEmptyFolder() async {
        let scanner = DiskMapScanner(root: root, walker: StubWalker(root: root, sizes: []))

        #expect(await events(of: scanner) == [
            .progress(DiskMapProgress()),
            .finished(DiskNode(url: root, kind: .folder, size: 0, fileCount: 0))
        ])
    }

    @Test func startsFromTheHomeFolderByDefault() {
        let scanner = DiskMapScanner(walker: StubWalker(root: root, sizes: []))

        #expect(scanner.root == FileManager.default.homeDirectoryForCurrentUser)
    }

    @Test func mapsTheHomeFolderOfTheCurrentUser() {
        #expect(DiskMapScanner.home().root == FileManager.default.homeDirectoryForCurrentUser)
    }

    // MARK: Cancellation

    @Test(.timeLimit(.minutes(1)))
    func stopsWalkingWhenTheConsumerStopsListening() async {
        let walker = EndlessWalker()
        let scanner = DiskMapScanner(root: root, walker: walker, progressInterval: 10)

        for await _ in scanner.scan() {
            break
        }

        for await _ in walker.finished {}
    }
}
