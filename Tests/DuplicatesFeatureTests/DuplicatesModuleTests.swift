import CleanMacCore
import CleanMacUI
import DuplicatesFeature
import Foundation
import Testing

@MainActor
struct DuplicatesModuleTests {
    private let downloads = URL(filePath: "/Users/test/Downloads")

    /// A module with its view model and its scanner, which refuses the folders given.
    ///
    /// - Parameter preferences: What the user chose, nothing unless told otherwise.
    private func makeModule(
        refusing refusedFolders: Set<URL> = [],
        preferences: Preferences? = nil
    ) -> (DuplicatesModule, DuplicatesViewModel, StubDuplicateScanner) {
        let scanner = StubDuplicateScanner(events: [], refusedFolders: refusedFolders)
        let viewModel = DuplicatesViewModel(
            scanner: scanner,
            cleanupService: CleanupService(remover: RecordingRemover())
        )
        let preferences = preferences ?? Preferences(storage: InMemoryPreferenceStorage())
        return (DuplicatesModule(viewModel: viewModel, preferences: preferences), viewModel, scanner)
    }

    /// The smallest size of each scan of a module whose preferences keep `storage`.
    private func scannedMinimumSizes(keeping storage: InMemoryPreferenceStorage) async -> [Int64] {
        let (_, viewModel, scanner) = makeModule(preferences: Preferences(storage: storage))

        await viewModel.startScan().value

        return scanner.scannedMinimumSizes
    }

    @Test func offersToFindDuplicatesInAFolder() throws {
        let (module, _, _) = makeModule()

        #expect(module.itemActions.count == 1)
        let action = try #require(module.itemActions.first)
        #expect(action.featureID == module.id)
        #expect(action.itemKind == .folder)
        #expect(action.symbolName == "doc.on.doc")
        #expect(!action.title.isEmpty)
    }

    @Test func scansTheFolderItIsOpenedWith() async {
        let (module, viewModel, scanner) = makeModule()

        module.show(itemAt: downloads)

        #expect(viewModel.scope == .folder(downloads))
        while viewModel.phase == .scanning {
            await Task.yield()
        }
        #expect(viewModel.phase == .review)
        #expect(scanner.scannedScopes == [.folder(downloads)])
    }

    @Test func ignoresAnItemItCannotScan() {
        let (module, viewModel, scanner) = makeModule(refusing: [downloads])

        module.show(itemAt: downloads)

        #expect(viewModel.phase == .intro)
        #expect(viewModel.scope == .home)
        #expect(scanner.scannedScopes.isEmpty)
    }

    // MARK: Smallest size

    @Test func offersSizesFrom100KBTo100MBWith1MBAsTheDefault() {
        let setting = DuplicatesSettings.minimumSize

        #expect(setting.defaultValue == 1_000_000)
        #expect(setting.allowedValues == [100_000, 1_000_000, 10_000_000, 100_000_000])
    }

    @Test func comparesFilesOf1MBUntilTheUserChooses() async {
        #expect(await scannedMinimumSizes(keeping: InMemoryPreferenceStorage()) == [1_000_000])
    }

    @Test func comparesFilesOfTheSizeTheUserChose() async {
        let storage = InMemoryPreferenceStorage(["duplicates.minimumSize": Int64(100_000)])

        #expect(await scannedMinimumSizes(keeping: storage) == [100_000])
    }

    @Test func ignoresASizeItDoesNotOffer() async {
        let storage = InMemoryPreferenceStorage(["duplicates.minimumSize": Int64(1)])

        #expect(await scannedMinimumSizes(keeping: storage) == [1_000_000])
    }

    @Test func theNextScanComparesTheSizeTheUserChooses() async {
        let preferences = Preferences(storage: InMemoryPreferenceStorage())
        let (module, viewModel, scanner) = makeModule(preferences: preferences)

        // The view model follows the preferences for as long as its module lives.
        withExtendedLifetime(module) {
            preferences.set(10_000_000, for: DuplicatesSettings.minimumSize)
        }
        await viewModel.startScan().value

        #expect(scanner.scannedMinimumSizes == [10_000_000])
        #expect(viewModel.minimumSize == 10_000_000)
    }

    // MARK: Folders left out

    /// The paths of the folders each scan of a module whose preferences keep `storage` left out.
    private func scannedExcludedPaths(keeping storage: InMemoryPreferenceStorage) async -> [[String]] {
        let (_, viewModel, scanner) = makeModule(preferences: Preferences(storage: storage))

        await viewModel.startScan().value

        return scanner.scannedExcludedFolders.map { folders in folders.map { $0.path } }
    }

    @Test func leavesOutNoFoldersUntilTheUserChoosesSome() async {
        #expect(await scannedExcludedPaths(keeping: InMemoryPreferenceStorage()) == [[]])
    }

    @Test func leavesOutTheFoldersTheUserChose() async {
        let storage = InMemoryPreferenceStorage(["scans.excludedFolders": ["/Users/test/Downloads", "/Users/test/Music"]])

        #expect(await scannedExcludedPaths(keeping: storage) == [["/Users/test/Downloads", "/Users/test/Music"]])
    }

    @Test func onlyTheNextScanLeavesOutTheFoldersTheUserChooses() async {
        let preferences = Preferences(storage: InMemoryPreferenceStorage())
        let (module, viewModel, scanner) = makeModule(preferences: preferences)
        let scanInProgress = viewModel.startScan()

        // The view model follows the preferences for as long as its module lives.
        withExtendedLifetime(module) {
            preferences.set([downloads.path], for: ScanSettings.excludedFolders)
        }
        await scanInProgress.value
        await viewModel.startScan().value

        #expect(scanner.scannedExcludedFolders.map { folders in folders.map { $0.path } } == [[], [downloads.path]])
    }

    /// Other features stop offering its action for the folders the user leaves out, and for
    /// the folders inside them, as they do for `~/Library`.
    @Test func takesNoFolderTheUserLeavesOut() throws {
        let home = try TemporaryFolder()
        let downloads = try home.makeFolder("Downloads")
        let installers = try home.makeFolder("Downloads/Installers")
        let documents = try home.makeFolder("Documents")
        let preferences = Preferences(storage: InMemoryPreferenceStorage())
        let scanner = DuplicateScanner(
            scopePolicy: ScanScopePolicy(home: home.root, excludedDirectories: [home.root.appending(path: "Library")])
        )
        let module = DuplicatesModule(
            viewModel: DuplicatesViewModel(scanner: scanner, cleanupService: CleanupService(remover: RecordingRemover())),
            preferences: preferences
        )

        preferences.set([downloads.path], for: ScanSettings.excludedFolders)

        #expect(!module.canShow(itemAt: downloads))
        #expect(!module.canShow(itemAt: installers))
        #expect(module.canShow(itemAt: documents))
        #expect(module.canShow(itemAt: home.root))

        preferences.set([], for: ScanSettings.excludedFolders)

        #expect(module.canShow(itemAt: installers))
    }

    @Test func addsItsSizeToTheAnalysisSettings() {
        let (module, _, _) = makeModule()

        #expect(module.settings.map(\.id) == ["duplicates.minimumSize"])
        #expect(module.settings.map(\.section) == [.analysis])
    }

    /// Other features offer its action only for the folders it would scan.
    @Test func takesOnlyTheFoldersTheScanOfTheHomeEnters() throws {
        let home = try TemporaryFolder()
        let documents = try home.makeFolder("Documents")
        let caches = try home.makeFolder("Library/Caches")
        let scanner = DuplicateScanner(
            scopePolicy: ScanScopePolicy(home: home.root, excludedDirectories: [home.root.appending(path: "Library")])
        )
        let module = DuplicatesModule(
            viewModel: DuplicatesViewModel(scanner: scanner, cleanupService: CleanupService(remover: RecordingRemover())),
            preferences: Preferences(storage: InMemoryPreferenceStorage())
        )

        #expect(module.canShow(itemAt: documents))
        #expect(module.canShow(itemAt: home.root))
        #expect(!module.canShow(itemAt: caches))
        #expect(!module.canShow(itemAt: home.root.appending(path: "Library")))
    }
}
