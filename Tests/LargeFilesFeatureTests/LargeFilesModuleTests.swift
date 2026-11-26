import CleanMacCore
import CleanMacUI
import Foundation
import LargeFilesFeature
import Testing

@MainActor
struct LargeFilesModuleTests {
    private let movies = URL(filePath: "/Users/test/Movies")
    private let preferences = Preferences(storage: InMemoryPreferenceStorage())

    private func makeViewModel(scanner: StubLargeFileScanner) -> LargeFilesViewModel {
        LargeFilesViewModel(scanner: scanner, cleanupService: CleanupService(remover: RecordingRemover()))
    }

    /// The smallest size of each scan of a module whose preferences keep `storage`.
    private func scannedMinimumSizes(keeping storage: InMemoryPreferenceStorage) async -> [Int64] {
        let scanner = StubLargeFileScanner(events: [])
        let viewModel = makeViewModel(scanner: scanner)
        _ = LargeFilesModule(viewModel: viewModel, preferences: Preferences(storage: storage))

        await viewModel.startScan().value

        return scanner.scannedMinimumSizes
    }

    @Test func offersOneActionForFolders() {
        let module = LargeFilesModule(viewModel: makeViewModel(scanner: StubLargeFileScanner(events: [])), preferences: preferences)

        let actions = module.itemActions

        // The id of an action is the id of its feature and the kind of item it takes.
        #expect(actions.map(\.id) == ["large-files.folder"])
        #expect(actions.allSatisfy { !$0.title.isEmpty && !$0.symbolName.isEmpty })
    }

    @Test func showingAFolderScansOnlyThatFolder() async {
        let scanner = StubLargeFileScanner(events: [])
        let viewModel = makeViewModel(scanner: scanner)
        let module = LargeFilesModule(viewModel: viewModel, preferences: preferences)

        module.show(itemAt: movies)
        #expect(viewModel.phase == .scanning)
        while viewModel.phase == .scanning {
            await Task.yield()
        }

        #expect(viewModel.scope == .folder(movies))
        #expect(scanner.scannedScopes == [.folder(movies)])
    }

    @Test func showingSomethingTheScannerCannotLookInDoesNothing() {
        let scanner = StubLargeFileScanner(events: [], unscannableFolders: [movies])
        let viewModel = makeViewModel(scanner: scanner)
        let module = LargeFilesModule(viewModel: viewModel, preferences: preferences)

        module.show(itemAt: movies)

        #expect(viewModel.phase == .intro)
        #expect(scanner.scannedScopes.isEmpty)
    }

    // MARK: Smallest size

    @Test func offersSizesFrom10MBTo1GBWith50MBAsTheDefault() {
        let setting = LargeFilesSettings.minimumSize

        #expect(setting.defaultValue == 50_000_000)
        #expect(setting.allowedValues == [10_000_000, 50_000_000, 100_000_000, 500_000_000, 1_000_000_000])
    }

    @Test func looksForFilesOf50MBUntilTheUserChooses() async {
        #expect(await scannedMinimumSizes(keeping: InMemoryPreferenceStorage()) == [50_000_000])
    }

    @Test func looksForFilesOfTheSizeTheUserChose() async {
        let storage = InMemoryPreferenceStorage(["largeFiles.minimumSize": Int64(500_000_000)])

        #expect(await scannedMinimumSizes(keeping: storage) == [500_000_000])
    }

    @Test func ignoresASizeItDoesNotOffer() async {
        let storage = InMemoryPreferenceStorage(["largeFiles.minimumSize": Int64(1)])

        #expect(await scannedMinimumSizes(keeping: storage) == [50_000_000])
    }

    @Test func theNextScanLooksForTheSizeTheUserChooses() async {
        let scanner = StubLargeFileScanner(events: [])
        let viewModel = makeViewModel(scanner: scanner)
        let module = LargeFilesModule(viewModel: viewModel, preferences: preferences)

        // The view model follows the preferences for as long as its module lives.
        withExtendedLifetime(module) {
            preferences.set(10_000_000, for: LargeFilesSettings.minimumSize)
        }
        await viewModel.startScan().value

        #expect(scanner.scannedMinimumSizes == [10_000_000])
        #expect(viewModel.minimumSize == 10_000_000)
    }

    // MARK: Folders left out

    /// The paths of the folders each scan of a module whose preferences keep `storage` left out.
    private func scannedExcludedPaths(keeping storage: InMemoryPreferenceStorage) async -> [[String]] {
        let scanner = StubLargeFileScanner(events: [])
        let viewModel = makeViewModel(scanner: scanner)
        _ = LargeFilesModule(viewModel: viewModel, preferences: Preferences(storage: storage))

        await viewModel.startScan().value

        return scanner.scannedExcludedFolders.map { folders in folders.map { $0.path } }
    }

    @Test func leavesOutNoFoldersUntilTheUserChoosesSome() async {
        #expect(await scannedExcludedPaths(keeping: InMemoryPreferenceStorage()) == [[]])
    }

    @Test func leavesOutTheFoldersTheUserChose() async {
        let storage = InMemoryPreferenceStorage(["scans.excludedFolders": ["/Users/test/Movies", "/Users/test/Music"]])

        #expect(await scannedExcludedPaths(keeping: storage) == [["/Users/test/Movies", "/Users/test/Music"]])
    }

    @Test func onlyTheNextScanLeavesOutTheFoldersTheUserChooses() async {
        let scanner = StubLargeFileScanner(events: [])
        let viewModel = makeViewModel(scanner: scanner)
        let module = LargeFilesModule(viewModel: viewModel, preferences: preferences)
        let scanInProgress = viewModel.startScan()

        // The view model follows the preferences for as long as its module lives.
        withExtendedLifetime(module) {
            preferences.set(["/Users/test/Movies"], for: ScanSettings.excludedFolders)
        }
        await scanInProgress.value
        await viewModel.startScan().value

        #expect(scanner.scannedExcludedFolders.map { folders in folders.map { $0.path } } == [[], ["/Users/test/Movies"]])
    }

    /// Other features stop offering its action for the folders the user leaves out, and for
    /// the folders inside them, as they do for `~/Library`.
    @Test func takesNoFolderTheUserLeavesOut() throws {
        let home = try TemporaryFolder()
        let trips = try home.makeFile("Movies/Trips/trip.mov").deletingLastPathComponent()
        let music = try home.makeFile("Music/song.mp3").deletingLastPathComponent()
        let movies = home.root.appending(path: "Movies")
        let scanner = LargeFileScanner(
            scopePolicy: ScanScopePolicy(home: home.root, excludedDirectories: [home.root.appending(path: "Library")])
        )
        let module = LargeFilesModule(viewModel: LargeFilesViewModel(
            scanner: scanner,
            cleanupService: CleanupService(remover: RecordingRemover())
        ), preferences: preferences)

        preferences.set([movies.path], for: ScanSettings.excludedFolders)

        #expect(!module.canShow(itemAt: movies))
        #expect(!module.canShow(itemAt: trips))
        #expect(module.canShow(itemAt: music))
        #expect(module.canShow(itemAt: home.root))

        preferences.set([], for: ScanSettings.excludedFolders)

        #expect(module.canShow(itemAt: trips))
    }

    @Test func addsItsSizeToTheAnalysisSettings() {
        let module = LargeFilesModule(viewModel: makeViewModel(scanner: StubLargeFileScanner(events: [])), preferences: preferences)

        #expect(module.settings.map(\.id) == ["largeFiles.minimumSize"])
        #expect(module.settings.map(\.section) == [.analysis])
    }

    /// Other features offer its action only for the folders it would look in.
    @Test func takesOnlyTheFoldersTheScanOfTheHomeEnters() throws {
        let home = try TemporaryFolder()
        try home.makeFile("Movies/trip.mov")
        try home.makeFile("Library/Caches/cache.bin")
        let scanner = LargeFileScanner(
            scopePolicy: ScanScopePolicy(home: home.root, excludedDirectories: [home.root.appending(path: "Library")])
        )
        let module = LargeFilesModule(viewModel: LargeFilesViewModel(
            scanner: scanner,
            cleanupService: CleanupService(remover: RecordingRemover())
        ), preferences: preferences)

        #expect(module.canShow(itemAt: home.root.appending(path: "Movies")))
        #expect(module.canShow(itemAt: home.root))
        #expect(!module.canShow(itemAt: home.root.appending(path: "Library/Caches")))
        #expect(!module.canShow(itemAt: home.root.appending(path: "Library")))
    }
}
