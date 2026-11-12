import CleanMacCore
import Combine
import Foundation
import LargeFilesFeature
import Testing

/// What the view model does when another feature sends it a folder to look in, in each of its
/// phases, and how it goes back to the whole home folder.
@MainActor
struct LargeFilesViewModelScopeTests {
    private typealias Fixtures = LargeFileFixtures

    private let movies = URL(filePath: "/Users/test/Movies")
    private let music = URL(filePath: "/Users/test/Music")

    private let trip = Fixtures.file("trip.mov", folder: "/Users/test/Movies", megabytes: 2_000)
    private let song = Fixtures.file("song.mp3", megabytes: 60)
    private let backup = Fixtures.file("backup.zip", megabytes: 300)

    /// Finds the three files in the home folder and only `trip`, among 7 files, in any other folder.
    private func makeScanner(
        finishes: Bool = true,
        unscannableFolders: Set<URL> = []
    ) -> StubLargeFileScanner {
        StubLargeFileScanner(
            events: [song, trip, backup].map { .found($0) },
            finishes: finishes,
            folderEvents: [.found(trip), .progress(scannedFiles: 7)],
            unscannableFolders: unscannableFolders
        )
    }

    private func makeViewModel(
        scanner: any LargeFileScanning,
        remover: RecordingRemover = RecordingRemover()
    ) -> LargeFilesViewModel {
        LargeFilesViewModel(
            scanner: scanner,
            cleanupService: CleanupService(remover: remover),
            now: { Fixtures.now },
            calendar: Fixtures.calendar
        )
    }

    private func report(of viewModel: LargeFilesViewModel) -> CleanupReport? {
        guard case .finished(let report) = viewModel.phase else { return nil }
        return report
    }

    // MARK: The home folder

    @Test func scansTheHomeFolderUntilAFolderIsSent() async {
        let scanner = makeScanner()
        let viewModel = makeViewModel(scanner: scanner)
        #expect(viewModel.scope == .home)

        await viewModel.startScan().value

        #expect(viewModel.scope == .home)
        #expect(scanner.scannedScopes == [.home])
    }

    // MARK: A folder sent in each phase

    @Test func aFolderSentOnTheIntroIsScannedRightAway() async {
        let scanner = makeScanner()
        let viewModel = makeViewModel(scanner: scanner)

        let scan = viewModel.scanFolder(at: movies)
        #expect(viewModel.phase == .scanning)
        #expect(viewModel.scope == .folder(movies))
        await scan?.value

        #expect(viewModel.phase == .review)
        #expect(viewModel.files == [trip])
        #expect(viewModel.scannedFileCount == 7)
        #expect(scanner.scannedScopes == [.folder(movies)])
    }

    @Test func aFolderSentDuringAScanReplacesTheScan() async {
        let scanner = makeScanner(finishes: false)
        let viewModel = makeViewModel(scanner: scanner)
        let homeScan = viewModel.startScan()
        while viewModel.foundCount < 3 {
            await Task.yield()
        }

        let folderScan = viewModel.scanFolder(at: movies)
        #expect(viewModel.phase == .scanning)
        #expect(viewModel.files.isEmpty)
        await homeScan.value
        await folderScan?.value

        #expect(viewModel.phase == .review)
        #expect(viewModel.scope == .folder(movies))
        #expect(viewModel.files == [trip])
        #expect(!viewModel.wasStoppedEarly)
        #expect(scanner.scannedScopes == [.home, .folder(movies)])
    }

    @Test func aFolderSentOverTheResultsReplacesThem() async {
        let scanner = makeScanner()
        let viewModel = makeViewModel(scanner: scanner)
        await viewModel.startScan().value
        viewModel.toggle(song)

        await viewModel.scanFolder(at: movies)?.value

        #expect(viewModel.phase == .review)
        #expect(viewModel.scope == .folder(movies))
        #expect(viewModel.files == [trip])
        #expect(!viewModel.hasSelection)
    }

    @Test func aFolderSentOverThePartialResultsOfAStoppedScanReplacesThem() async {
        let viewModel = makeViewModel(scanner: makeScanner(finishes: false))
        let homeScan = viewModel.startScan()
        viewModel.stopScan()
        await homeScan.value

        await viewModel.scanFolder(at: movies)?.value

        #expect(viewModel.scope == .folder(movies))
        #expect(viewModel.files == [trip])
        #expect(!viewModel.wasStoppedEarly)
    }

    @Test func aFolderSentOverTheResultsOfAnotherFolderReplacesThem() async {
        let scanner = makeScanner()
        let viewModel = makeViewModel(scanner: scanner)
        await viewModel.scanFolder(at: movies)?.value

        await viewModel.scanFolder(at: music)?.value

        #expect(viewModel.scope == .folder(music))
        #expect(scanner.scannedScopes == [.folder(movies), .folder(music)])
    }

    @Test func aFolderSentWhileRemovingWaitsWithoutDisturbingTheRemoval() async {
        let scanner = makeScanner()
        let remover = RecordingRemover()
        let viewModel = makeViewModel(scanner: scanner, remover: remover)
        await viewModel.startScan().value
        viewModel.toggle(song)
        let removal = viewModel.remove()
        #expect(viewModel.phase == .removing)

        #expect(viewModel.scanFolder(at: movies) == nil)
        #expect(viewModel.phase == .removing)
        await removal?.value

        #expect(report(of: viewModel)?.removedCount == 1)
        #expect(remover.removed == [song.id])
        #expect(viewModel.scope == .home)
        #expect(viewModel.files == [trip, backup])
        #expect(scanner.scannedScopes == [.home])
    }

    @Test func doneScansTheFolderSentWhileRemoving() async {
        let scanner = makeScanner()
        let viewModel = makeViewModel(scanner: scanner)
        await viewModel.startScan().value
        viewModel.toggle(song)
        let removal = viewModel.remove()
        viewModel.scanFolder(at: movies)
        await removal?.value

        await viewModel.done()?.value

        #expect(viewModel.phase == .review)
        #expect(viewModel.scope == .folder(movies))
        #expect(viewModel.files == [trip])
        #expect(scanner.scannedScopes == [.home, .folder(movies)])
    }

    @Test func aFolderSentOverTheReportOfARemovalWaitsForDone() async {
        let scanner = makeScanner()
        let viewModel = makeViewModel(scanner: scanner)
        await viewModel.startScan().value
        viewModel.toggle(song)
        await viewModel.remove()?.value

        #expect(viewModel.scanFolder(at: movies) == nil)
        #expect(report(of: viewModel)?.removedCount == 1)
        #expect(viewModel.scope == .home)
        #expect(scanner.scannedScopes == [.home])

        await viewModel.done()?.value
        #expect(viewModel.phase == .review)
        #expect(viewModel.scope == .folder(movies))
        #expect(viewModel.files == [trip])
    }

    @Test func theLastFolderSentDuringARemovalIsTheOneScanned() async {
        let scanner = makeScanner()
        let viewModel = makeViewModel(scanner: scanner)
        await viewModel.startScan().value
        viewModel.toggle(song)
        await viewModel.remove()?.value
        viewModel.scanFolder(at: movies)
        viewModel.scanFolder(at: music)

        await viewModel.done()?.value

        #expect(scanner.scannedScopes == [.home, .folder(music)])
    }

    @Test func aFolderSentDuringARemovalIsScannedOnlyOnce() async {
        let scanner = makeScanner()
        let viewModel = makeViewModel(scanner: scanner)
        await viewModel.startScan().value
        viewModel.toggle(song)
        await viewModel.remove()?.value
        viewModel.scanFolder(at: movies)
        await viewModel.done()?.value
        viewModel.toggle(trip)
        await viewModel.remove()?.value

        #expect(viewModel.done() == nil)

        #expect(viewModel.phase == .review)
        #expect(viewModel.scope == .folder(movies))
        #expect(viewModel.files.isEmpty)
        #expect(scanner.scannedScopes == [.home, .folder(movies)])
    }

    // MARK: Folders the scanner can't look in

    @Test func ignoresOnTheIntroAFolderTheScannerCannotLookIn() {
        let scanner = makeScanner(unscannableFolders: [movies])
        let viewModel = makeViewModel(scanner: scanner)

        #expect(viewModel.scanFolder(at: movies) == nil)

        #expect(viewModel.phase == .intro)
        #expect(viewModel.scope == .home)
        #expect(scanner.scannedScopes.isEmpty)
    }

    @Test func keepsTheResultsWhenSentAFolderTheScannerCannotLookIn() async {
        let scanner = makeScanner(unscannableFolders: [movies])
        let viewModel = makeViewModel(scanner: scanner)
        await viewModel.startScan().value
        viewModel.toggle(song)
        viewModel.filter.kinds = [.audio]

        #expect(viewModel.scanFolder(at: movies) == nil)

        #expect(viewModel.phase == .review)
        #expect(viewModel.scope == .home)
        #expect(viewModel.foundCount == 3)
        #expect(viewModel.isSelected(song))
        #expect(viewModel.filter.kinds == [.audio])
        #expect(scanner.scannedScopes == [.home])
    }

    @Test func aFolderTheScannerCannotLookInIsNotLeftForAfterARemoval() async {
        let scanner = makeScanner(unscannableFolders: [movies])
        let viewModel = makeViewModel(scanner: scanner)
        await viewModel.startScan().value
        viewModel.toggle(song)
        await viewModel.remove()?.value
        viewModel.scanFolder(at: movies)

        #expect(viewModel.done() == nil)

        #expect(viewModel.phase == .review)
        #expect(viewModel.scope == .home)
    }

    // MARK: Scanning again, stopping and going back to the home folder

    @Test func scanningAgainStaysInTheFolder() async {
        let scanner = makeScanner()
        let viewModel = makeViewModel(scanner: scanner)
        await viewModel.scanFolder(at: movies)?.value

        await viewModel.startScan().value

        #expect(viewModel.scope == .folder(movies))
        #expect(viewModel.files == [trip])
        #expect(scanner.scannedScopes == [.folder(movies), .folder(movies)])
    }

    @Test func scanningTheHomeLeavesTheFolder() async {
        let scanner = makeScanner()
        let viewModel = makeViewModel(scanner: scanner)
        await viewModel.scanFolder(at: movies)?.value

        await viewModel.scanHome().value

        #expect(viewModel.phase == .review)
        #expect(viewModel.scope == .home)
        #expect(viewModel.files == [song, trip, backup])
        #expect(scanner.scannedScopes == [.folder(movies), .home])
    }

    @Test func scanningTheHomeReplacesTheScanOfAFolderInProgress() async {
        let viewModel = makeViewModel(scanner: makeScanner())
        let folderScan = viewModel.scanFolder(at: movies)

        let homeScan = viewModel.scanHome()
        #expect(viewModel.phase == .scanning)
        #expect(viewModel.scope == .home)
        await folderScan?.value
        await homeScan.value

        #expect(viewModel.phase == .review)
        #expect(viewModel.scope == .home)
        #expect(viewModel.files == [song, trip, backup])
    }

    @Test func stoppingTheScanOfAFolderReviewsWhatWasFoundInIt() async {
        let scanner = ManualLargeFileScanner()
        let viewModel = makeViewModel(scanner: scanner)
        let scan = viewModel.scanFolder(at: movies)
        scanner.send(.found(trip))
        while viewModel.foundCount == 0 {
            await Task.yield()
        }

        viewModel.stopScan()
        await scan?.value

        #expect(viewModel.phase == .review)
        #expect(viewModel.wasStoppedEarly)
        #expect(viewModel.scope == .folder(movies))
        #expect(viewModel.files == [trip])
    }

    // MARK: Filter and derived state

    @Test func clearsTheFilterWhenTheScanLooksSomewhereElse() async {
        let viewModel = makeViewModel(scanner: makeScanner())
        await viewModel.startScan().value
        viewModel.filter = LargeFileFilter(kinds: [.audio], searchText: "song")
        viewModel.sortOrder = .name

        await viewModel.scanFolder(at: movies)?.value
        #expect(viewModel.filter == LargeFileFilter())
        #expect(viewModel.visibleFiles == [trip])
        #expect(viewModel.sortOrder == .name)

        viewModel.filter.kinds = [.archive]
        await viewModel.scanHome().value
        #expect(viewModel.filter == LargeFileFilter())
        #expect(viewModel.visibleFiles == [backup, song, trip])
    }

    @Test func keepsTheFilterWhenTheScanLooksInTheSamePlaceAgain() async {
        let viewModel = makeViewModel(scanner: makeScanner())
        await viewModel.scanFolder(at: movies)?.value
        viewModel.filter.kinds = [.audio]

        await viewModel.startScan().value
        #expect(viewModel.filter.kinds == [.audio])

        await viewModel.scanFolder(at: movies)?.value
        #expect(viewModel.filter.kinds == [.audio])
        #expect(viewModel.visibleFiles.isEmpty)
    }

    /// The values kept between reads come from the files of the home folder. They're read
    /// first, so they are in memory, and must follow the files of the folder.
    @Test func everyValueKeptBetweenReadsFollowsTheFilesOfTheNewScope() async {
        let viewModel = makeViewModel(scanner: makeScanner())
        await viewModel.startScan().value
        viewModel.filter.kinds = [.audio, .archive]
        viewModel.toggleAll()
        #expect(viewModel.foundSize == 2_360_000_000)
        #expect(viewModel.visibleFiles == [backup, song])
        #expect(viewModel.filterCounts.count(of: .audio) == 1)
        #expect(viewModel.selectedItems == [song.item, backup.item])
        #expect(viewModel.allSelectionState == .all)
        #expect(viewModel.kindOptions == [.archive, .video, .audio])

        await viewModel.scanFolder(at: movies)?.value

        #expect(viewModel.foundSize == 2_000_000_000)
        #expect(viewModel.visibleFiles == [trip])
        #expect(viewModel.filterCounts.count(of: .audio) == 0)
        #expect(viewModel.filterCounts.count(of: .video) == 1)
        #expect(viewModel.selectedItems.isEmpty)
        #expect(viewModel.allSelectionState == .none)
        #expect(viewModel.kindOptions == [.video])
    }

    /// Every announcement draws the screen again, so a scan of the same place announces
    /// neither the scope nor the filter.
    @Test func announcesTheScopeAndTheFilterOnlyWhenTheScanLooksSomewhereElse() async {
        let viewModel = makeViewModel(scanner: makeScanner())
        var announcements = 0
        let observation = viewModel.objectWillChange.sink { announcements += 1 }

        await viewModel.scanFolder(at: movies)?.value
        // The scope and the filter, then clearing the files, the selection, the count and the
        // warning, starting, the file found, the count and the review.
        #expect(announcements == 10)

        announcements = 0
        await viewModel.startScan().value
        #expect(announcements == 8)
        observation.cancel()
    }
}
