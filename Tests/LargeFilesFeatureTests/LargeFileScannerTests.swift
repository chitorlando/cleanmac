import Foundation
import LargeFilesFeature
import Testing

struct LargeFileScannerTests {
    private let root = URL(filePath: "/tmp")

    private func events(of scanner: LargeFileScanner) async -> [LargeFileScanEvent] {
        var events: [LargeFileScanEvent] = []
        for await event in scanner.scan() {
            events.append(event)
        }
        return events
    }

    private func foundSizes(_ events: [LargeFileScanEvent]) -> [Int64] {
        events.compactMap { event in
            if case .found(let file) = event { file.item.size } else { nil }
        }
    }

    private func progressCounts(_ events: [LargeFileScanEvent]) -> [Int] {
        events.compactMap { event in
            if case .progress(let count) = event { count } else { nil }
        }
    }

    @Test func reportsOnlyFilesThatMatchTheCriteria() async {
        let scanner = LargeFileScanner(
            root: root,
            criteria: LargeFileCriteria(minimumSize: 100),
            walker: StubWalker(sizes: [10, 150, 99, 100, 5_000])
        )

        #expect(foundSizes(await events(of: scanner)) == [150, 100, 5_000])
    }

    @Test func reportsProgressEveryIntervalAndAtTheEnd() async {
        let scanner = LargeFileScanner(
            root: root,
            criteria: LargeFileCriteria(minimumSize: 1_000),
            walker: StubWalker(sizes: Array(repeating: 1, count: 7)),
            progressInterval: 3
        )

        #expect(progressCounts(await events(of: scanner)) == [3, 6, 7])
    }

    @Test func doesNotRepeatTheLastProgressWhenItFallsOnTheInterval() async {
        let scanner = LargeFileScanner(
            root: root,
            walker: StubWalker(sizes: Array(repeating: 1, count: 6)),
            progressInterval: 3
        )

        #expect(progressCounts(await events(of: scanner)) == [3, 6])
    }

    @Test func reportsZeroFilesForAnEmptyFolder() async {
        let scanner = LargeFileScanner(root: root, walker: StubWalker(sizes: []))

        #expect(await events(of: scanner) == [.progress(scannedFiles: 0)])
    }

    @Test(.timeLimit(.minutes(1)))
    func stopsWalkingWhenTheConsumerStopsListening() async {
        let walker = EndlessWalker()
        let scanner = LargeFileScanner(root: root, criteria: LargeFileCriteria(minimumSize: 1), walker: walker)

        for await _ in scanner.scan() {
            break
        }

        for await _ in walker.finished {}
    }

    @Test func findsLargeFilesOnDisk() async throws {
        let folder = try TemporaryFolder()
        try folder.makeFile("Movies/big.mov", size: 200_000)
        try folder.makeFile("Documents/small.txt", size: 1_000)
        try folder.makeFile(".hidden/big.bin", size: 200_000)

        let scanner = LargeFileScanner(
            root: folder.root,
            criteria: LargeFileCriteria(minimumSize: 100_000),
            walker: FileSystemWalker(excludedDirectories: [])
        )
        let found = await events(of: scanner).compactMap { event in
            if case .found(let file) = event { file } else { nil }
        }

        #expect(found.map(\.item.name) == ["big.mov"])
        #expect(found.first?.kind == .video)
    }
}
