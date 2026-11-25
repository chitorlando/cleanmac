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
        in scope: ScanScope = .home,
        excluding excludedFolders: [URL] = [],
        criteria: LargeFileCriteria = LargeFileCriteria(minimumSize: 100_000)
    ) async -> [LargeFileScanEvent] {
        var events: [LargeFileScanEvent] = []
        for await event in scanner.scan(scope, excluding: excludedFolders, criteria: criteria) {
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
        LargeFileScanner(
            scopePolicy: ScanScopePolicy(home: home.root, excludedDirectories: [home.root.appending(path: "Library")])
        )
    }

    @Test func reportsOnlyFilesThatMatchTheCriteria() async {
        let scanner = LargeFileScanner(scopePolicy: scopePolicy, makeWalker: { _ in StubWalker(sizes: [10, 150, 99, 100, 5_000]) })

        let scanned = await events(of: scanner, criteria: LargeFileCriteria(minimumSize: 100))

        #expect(foundSizes(scanned) == [150, 100, 5_000])
    }

    @Test func eachScanLooksForTheSmallestSizeItIsGiven() async {
        let scanner = LargeFileScanner(scopePolicy: scopePolicy, makeWalker: { _ in StubWalker(sizes: [10, 150, 5_000]) })

        let first = await events(of: scanner, criteria: LargeFileCriteria(minimumSize: 100))
        let second = await events(of: scanner, criteria: LargeFileCriteria(minimumSize: 1_000))

        #expect(foundSizes(first) == [150, 5_000])
        #expect(foundSizes(second) == [5_000])
    }

    @Test func reportsProgressEveryIntervalAndAtTheEnd() async {
        let scanner = LargeFileScanner(
            scopePolicy: scopePolicy,
            makeWalker: { _ in StubWalker(sizes: Array(repeating: 1, count: 7)) },
            progressInterval: 3
        )

        #expect(progressCounts(await events(of: scanner)) == [3, 6, 7])
    }

    @Test func doesNotRepeatTheLastProgressWhenItFallsOnTheInterval() async {
        let scanner = LargeFileScanner(
            scopePolicy: scopePolicy,
            makeWalker: { _ in StubWalker(sizes: Array(repeating: 1, count: 6)) },
            progressInterval: 3
        )

        #expect(progressCounts(await events(of: scanner)) == [3, 6])
    }

    @Test func reportsZeroFilesForAnEmptyFolder() async {
        let scanner = LargeFileScanner(scopePolicy: scopePolicy, makeWalker: { _ in StubWalker(sizes: []) })

        #expect(await events(of: scanner) == [.progress(scannedFiles: 0)])
    }

    @Test(.timeLimit(.minutes(1)))
    func stopsWalkingWhenTheConsumerStopsListening() async {
        let walker = EndlessWalker()
        let scanner = LargeFileScanner(scopePolicy: scopePolicy, makeWalker: { _ in walker })

        for await _ in scanner.scan(.home, excluding: [], criteria: LargeFileCriteria(minimumSize: 1)) {
            break
        }

        for await _ in walker.finished {}
    }

    @Test func findsLargeFilesOnDisk() async throws {
        let folder = try TemporaryFolder()
        try folder.makeFile("Movies/big.mov", size: 200_000)
        try folder.makeFile("Documents/small.txt", size: 1_000)
        try folder.makeFile(".hidden/big.bin", size: 200_000)

        let scanner = LargeFileScanner(scopePolicy: ScanScopePolicy(home: folder.root))
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
        let movies = try #require(scanner.scope(limitedTo: home.root.appending(path: "Movies"), excluding: []))

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
        let movies = try #require(scanner.scope(limitedTo: home.root.appending(path: "Movies"), excluding: []))

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
            #expect(scanner.scope(limitedTo: home.root.appending(path: path), excluding: []) == nil, "\(path)")
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
        let scope = try #require(scanner.scope(limitedTo: movies, excluding: []))

        try FileManager.default.removeItem(at: movies)

        #expect(await events(of: scanner, in: scope) == [.progress(scannedFiles: 0)])
    }

    // MARK: Folders left out of one scan

    @Test func skipsTheFoldersAScanLeavesOut() async throws {
        let home = try TemporaryFolder()
        try home.makeFile("Movies/trip.mov", size: 200_000)
        try home.makeFile("Music/Live/concert.mov", size: 200_000)
        let scanner = makeScanner(home: home)
        let music = home.root.appending(path: "Music")

        #expect(foundNames(await events(of: scanner, excluding: [music])) == ["trip.mov"])
        #expect(foundNames(await events(of: scanner)).sorted() == ["concert.mov", "trip.mov"])
    }

    @Test func cannotBeLimitedToAFolderTheScanLeavesOut() async throws {
        let home = try TemporaryFolder()
        let live = try home.makeFile("Music/Live/concert.mov").deletingLastPathComponent()
        let music = home.root.appending(path: "Music")
        let scanner = makeScanner(home: home)

        #expect(scanner.scope(limitedTo: music, excluding: [music]) == nil)
        #expect(scanner.scope(limitedTo: live, excluding: [music]) == nil)
        #expect(scanner.scope(limitedTo: live, excluding: [])?.folder?.path == live.path)
        #expect(scanner.scope(limitedTo: home.root, excluding: [music]) == .home)
    }

    @Test func findsNothingInAFolderTheScanLeavesOut() async throws {
        let home = try TemporaryFolder()
        let live = try home.makeFile("Music/Live/concert.mov", size: 200_000).deletingLastPathComponent()
        let music = home.root.appending(path: "Music")
        let scanner = makeScanner(home: home)
        let scope = try #require(scanner.scope(limitedTo: live, excluding: []))

        #expect(await events(of: scanner, in: scope, excluding: [music]) == [.progress(scannedFiles: 0)])
    }

    /// The walker of each scan skips the folders the scanner always leaves out and those left
    /// out of that scan, the ones the scope policy of the scan refuses.
    @Test func givesTheWalkerOfEachScanTheFoldersItLeavesOut() async {
        let library = URL(filePath: "/Users/test/Library")
        let music = URL(filePath: "/Users/test/Music")
        let walkers = WalkerRecorder()
        let scanner = LargeFileScanner(
            scopePolicy: ScanScopePolicy(home: URL(filePath: "/Users/test"), excludedDirectories: [library]),
            makeWalker: { excludedDirectories in
                walkers.record(excludedDirectories)
                return StubWalker(sizes: [])
            }
        )

        _ = await events(of: scanner, excluding: [music])
        _ = await events(of: scanner)

        #expect(walkers.excludedDirectories == [[library, music], [library]])
    }
}
