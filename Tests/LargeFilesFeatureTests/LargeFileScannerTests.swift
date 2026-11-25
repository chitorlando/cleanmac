import CleanMacCore
import Foundation
import LargeFilesFeature
import Testing

struct LargeFileScannerTests {
    private let scopePolicy = ScanScopePolicy(home: URL(filePath: "/tmp"))

    /// - Parameter criteria: Files of 100 KB or more unless told otherwise, as the tests
    ///   write larger ones on disk.
    private func events(
        of scanner: LargeFileScanner,
        in scope: LargeFileScanScope = .home,
        criteria: LargeFileCriteria = LargeFileCriteria(minimumSize: 100_000)
    ) async -> [LargeFileScanEvent] {
        var events: [LargeFileScanEvent] = []
        for await event in scanner.scan(scope, criteria: criteria) {
            events.append(event)
        }
        return events
    }

    private func foundSizes(_ events: [LargeFileScanEvent]) -> [Int64] {
        events.compactMap { event in
            if case .found(let file) = event { file.item.size } else { nil }
        }
    }

    private func foundNames(_ events: [LargeFileScanEvent]) -> [String] {
        events.compactMap { event in
            if case .found(let file) = event { file.name } else { nil }
        }
    }

    private func progressCounts(_ events: [LargeFileScanEvent]) -> [Int] {
        events.compactMap { event in
            if case .progress(let count) = event { count } else { nil }
        }
    }

    /// Scanner of a home folder on disk that leaves its `Library` out, as the app does with `~/Library`.
    private func makeScanner(home: TemporaryFolder) -> LargeFileScanner {
        let excludedDirectories = [home.root.appending(path: "Library")]
        return LargeFileScanner(
            scopePolicy: ScanScopePolicy(home: home.root, excludedDirectories: excludedDirectories),
            walker: FileSystemWalker(excludedDirectories: excludedDirectories)
        )
    }

    @Test func reportsOnlyFilesThatMatchTheCriteria() async {
        let scanner = LargeFileScanner(scopePolicy: scopePolicy, walker: StubWalker(sizes: [10, 150, 99, 100, 5_000]))

        let scanned = await events(of: scanner, criteria: LargeFileCriteria(minimumSize: 100))

        #expect(foundSizes(scanned) == [150, 100, 5_000])
    }

    @Test func eachScanLooksForTheSmallestSizeItIsGiven() async {
        let scanner = LargeFileScanner(scopePolicy: scopePolicy, walker: StubWalker(sizes: [10, 150, 5_000]))

        let first = await events(of: scanner, criteria: LargeFileCriteria(minimumSize: 100))
        let second = await events(of: scanner, criteria: LargeFileCriteria(minimumSize: 1_000))

        #expect(foundSizes(first) == [150, 5_000])
        #expect(foundSizes(second) == [5_000])
    }

    @Test func reportsProgressEveryIntervalAndAtTheEnd() async {
        let scanner = LargeFileScanner(
            scopePolicy: scopePolicy,
            walker: StubWalker(sizes: Array(repeating: 1, count: 7)),
            progressInterval: 3
        )

        #expect(progressCounts(await events(of: scanner)) == [3, 6, 7])
    }

    @Test func doesNotRepeatTheLastProgressWhenItFallsOnTheInterval() async {
        let scanner = LargeFileScanner(
            scopePolicy: scopePolicy,
            walker: StubWalker(sizes: Array(repeating: 1, count: 6)),
            progressInterval: 3
        )

        #expect(progressCounts(await events(of: scanner)) == [3, 6])
    }

    @Test func reportsZeroFilesForAnEmptyFolder() async {
        let scanner = LargeFileScanner(scopePolicy: scopePolicy, walker: StubWalker(sizes: []))

        #expect(await events(of: scanner) == [.progress(scannedFiles: 0)])
    }

    @Test(.timeLimit(.minutes(1)))
    func stopsWalkingWhenTheConsumerStopsListening() async {
        let walker = EndlessWalker()
        let scanner = LargeFileScanner(scopePolicy: scopePolicy, walker: walker)

        for await _ in scanner.scan(.home, criteria: LargeFileCriteria(minimumSize: 1)) {
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
            scopePolicy: ScanScopePolicy(home: folder.root),
            walker: FileSystemWalker(excludedDirectories: [])
        )
        let found = await events(of: scanner).compactMap { event in
            if case .found(let file) = event { file } else { nil }
        }

        #expect(found.map(\.item.name) == ["big.mov"])
        #expect(found.first?.kind == .video)
    }

    // MARK: A single folder

    @Test func findsOnlyTheLargeFilesOfTheFolderItIsLimitedTo() async throws {
        let home = try TemporaryFolder()
        try home.makeFile("Movies/Trips/trip.mov", size: 200_000)
        try home.makeFile("Movies/notes.txt", size: 1_000)
        try home.makeFile("Music/album.zip", size: 200_000)
        let scanner = makeScanner(home: home)
        let movies = try #require(scanner.scope(limitedTo: home.root.appending(path: "Movies")))

        let scanned = await events(of: scanner, in: movies)

        #expect(foundNames(scanned) == ["trip.mov"])
        #expect(progressCounts(scanned) == [2])
    }

    @Test func skipsInAFolderWhatTheScanOfTheHomeSkips() async throws {
        let home = try TemporaryFolder()
        try home.makeFile("Movies/trip.mov", size: 200_000)
        try home.makeFile("Movies/.cache/render.bin", size: 200_000)
        try home.makeFile("Movies/Editor.app/Contents/editor.bin", size: 200_000)
        let scanner = makeScanner(home: home)
        let movies = try #require(scanner.scope(limitedTo: home.root.appending(path: "Movies")))

        #expect(foundNames(await events(of: scanner, in: movies)) == ["trip.mov"])
        #expect(foundNames(await events(of: scanner)) == ["trip.mov"])
    }

    @Test func cannotBeLimitedToAFolderTheScanOfTheHomeNeverEnters() async throws {
        let home = try TemporaryFolder()
        try home.makeFile("Library/Caches/cache.bin", size: 200_000)
        try home.makeFile(".cache/render.bin", size: 200_000)
        try home.makeFile("Editor.app/Contents/editor.bin", size: 200_000)
        let scanner = makeScanner(home: home)

        for path in ["Library", "Library/Caches", ".cache", "Editor.app", "Editor.app/Contents"] {
            #expect(scanner.scope(limitedTo: home.root.appending(path: path)) == nil, "\(path)")
        }
    }

    /// The walk starts from the folder of the scope, which a walker enters whatever it is, so
    /// the scanner itself has to refuse the folders it couldn't be limited to.
    @Test func findsNothingInAFolderTheScanOfTheHomeNeverEnters() async throws {
        let home = try TemporaryFolder()
        try home.makeFile("Library/Caches/cache.bin", size: 200_000)
        try home.makeFile(".cache/render.bin", size: 200_000)
        try home.makeFile("Editor.app/Contents/editor.bin", size: 200_000)
        let scanner = makeScanner(home: home)

        for path in ["Library", "Library/Caches", ".cache", "Editor.app", "Editor.app/Contents"] {
            let scanned = await events(of: scanner, in: .folder(home.root.appending(path: path)))
            #expect(scanned == [.progress(scannedFiles: 0)], "\(path)")
        }
        #expect(foundNames(await events(of: scanner)).isEmpty)
    }

    @Test func findsNothingOnceTheFolderIsGone() async throws {
        let home = try TemporaryFolder()
        let movies = try home.makeFile("Movies/trip.mov", size: 200_000).deletingLastPathComponent()
        let scanner = makeScanner(home: home)
        let scope = try #require(scanner.scope(limitedTo: movies))

        try FileManager.default.removeItem(at: movies)

        #expect(await events(of: scanner, in: scope) == [.progress(scannedFiles: 0)])
    }
}
