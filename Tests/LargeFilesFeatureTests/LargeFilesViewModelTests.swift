import CleanMacCore
import Combine
import Foundation
import LargeFilesFeature
import Testing

@MainActor
struct LargeFilesViewModelTests {
    private typealias Fixtures = LargeFileFixtures

    private let trip = Fixtures.file("trip.mov", megabytes: 2_000, lastUsed: Fixtures.date(2024, 1, 1))
    private let song = Fixtures.file("song.mp3", megabytes: 60, lastUsed: Fixtures.date(2026, 11, 1))
    private let backup = Fixtures.file("backup.zip", megabytes: 300, lastUsed: Fixtures.date(2026, 8, 1))

    private var allFiles: [LargeFile] { [song, trip, backup] }

    private func makeViewModel(
        events: [LargeFileScanEvent]? = nil,
        finishes: Bool = true,
        remover: RecordingRemover = RecordingRemover()
    ) -> LargeFilesViewModel {
        let events = events ?? [.progress(scannedFiles: 500)] + allFiles.map { .found($0) } + [.progress(scannedFiles: 812)]
        return LargeFilesViewModel(
            scanner: StubLargeFileScanner(events: events, finishes: finishes),
            cleanupService: CleanupService(remover: remover),
            now: { Fixtures.now },
            calendar: Fixtures.calendar
        )
    }

    private func scannedViewModel(remover: RecordingRemover = RecordingRemover()) async -> LargeFilesViewModel {
        let viewModel = makeViewModel(remover: remover)
        await viewModel.startScan().value
        return viewModel
    }

    private func report(of viewModel: LargeFilesViewModel) -> CleanupReport? {
        guard case .finished(let report) = viewModel.phase else { return nil }
        return report
    }

    // MARK: Phases and progress

    @Test func startsOnTheIntro() {
        let viewModel = makeViewModel()

        #expect(viewModel.phase == .intro)
        #expect(viewModel.scannedFileCount == 0)
        #expect(viewModel.foundCount == 0)
    }

    @Test func reportsProgressWhileScanning() async {
        let viewModel = makeViewModel(events: [.progress(scannedFiles: 500), .found(trip)], finishes: false)

        let task = viewModel.startScan()
        while viewModel.foundCount == 0 {
            await Task.yield()
        }

        #expect(viewModel.phase == .scanning)
        #expect(viewModel.scannedFileCount == 500)
        #expect(viewModel.files == [trip])
        viewModel.stopScan()
        await task.value
    }

    @Test func collectsEveryFoundFileAndStartsTheReview() async {
        let viewModel = await scannedViewModel()

        #expect(viewModel.phase == .review)
        #expect(viewModel.scannedFileCount == 812)
        #expect(viewModel.foundCount == 3)
        #expect(viewModel.foundSize == 2_360_000_000)
    }

    @Test func announcesEveryChangeToTheFilesFound() async {
        let viewModel = makeViewModel(events: allFiles.map { .found($0) })
        var announcements = 0
        let observation = viewModel.objectWillChange.sink { announcements += 1 }

        await viewModel.startScan().value
        // Clearing the files, the selection, the count and the warning, starting, three files
        // found and the review.
        #expect(announcements == 9)

        viewModel.toggle(trip)
        announcements = 0
        await viewModel.remove()?.value
        // Removing, the files left, the selection and the report.
        #expect(announcements == 4)
        #expect(viewModel.files == [song, backup])
        observation.cancel()
    }

    @Test func aCompleteScanIsNotMarkedAsStopped() async {
        let viewModel = await scannedViewModel()

        #expect(!viewModel.wasStoppedEarly)
    }

    @Test func exposesTheMinimumSizeTheScannerLooksFor() {
        let scanner = StubLargeFileScanner(events: [], criteria: LargeFileCriteria(minimumSize: 200_000_000))
        let viewModel = LargeFilesViewModel(scanner: scanner, cleanupService: CleanupService(remover: RecordingRemover()))

        #expect(viewModel.minimumSize == 200_000_000)
    }

    @Test func stoppingTheScanReviewsThePartialResults() async {
        let viewModel = makeViewModel(events: [.progress(scannedFiles: 500), .found(trip)], finishes: false)

        let task = viewModel.startScan()
        while viewModel.foundCount == 0 {
            await Task.yield()
        }
        viewModel.stopScan()
        await task.value

        #expect(viewModel.phase == .review)
        #expect(viewModel.wasStoppedEarly)
        #expect(viewModel.files == [trip])
        #expect(viewModel.scannedFileCount == 500)
    }

    @Test func stoppingIsIgnoredWhenNotScanning() async {
        let viewModel = await scannedViewModel()
        viewModel.toggle(trip)
        await viewModel.remove()?.value

        viewModel.stopScan()

        #expect(!viewModel.wasStoppedEarly)
        #expect(report(of: viewModel) != nil)
    }

    @Test func scanningAgainClearsTheStoppedWarning() async {
        let viewModel = makeViewModel(events: [.found(trip)], finishes: false)
        let firstScan = viewModel.startScan()
        viewModel.stopScan()
        await firstScan.value

        let secondScan = viewModel.startScan()

        #expect(!viewModel.wasStoppedEarly)
        #expect(viewModel.phase == .scanning)
        #expect(viewModel.files.isEmpty)
        viewModel.stopScan()
        await secondScan.value
    }

    // MARK: Filters and order

    @Test func sortsBySizeByDefault() async {
        let viewModel = await scannedViewModel()

        #expect(viewModel.visibleFiles == [trip, backup, song])
    }

    @Test func appliesTheChosenOrder() async {
        let viewModel = await scannedViewModel()

        viewModel.sortOrder = .lastAccess
        #expect(viewModel.visibleFiles == [trip, backup, song])

        viewModel.sortOrder = .name
        #expect(viewModel.visibleFiles == [backup, song, trip])
    }

    @Test func appliesTheFilter() async {
        let viewModel = await scannedViewModel()

        viewModel.filter.kinds = [.audio, .archive]
        #expect(viewModel.visibleFiles == [backup, song])

        viewModel.filter.ageBucket = .lessThanOneMonth
        #expect(viewModel.visibleFiles == [song])
    }

    @Test func groupsFilesByAgeUsingTheInjectedDate() async {
        let viewModel = await scannedViewModel()

        viewModel.filter.ageBucket = .overOneYear

        #expect(viewModel.visibleFiles == [trip])
    }

    @Test func countsTheFilesOfEachFilterOption() async {
        let viewModel = await scannedViewModel()
        viewModel.filter.kinds = [.video]

        let counts = viewModel.filterCounts

        #expect(counts.count(of: .audio) == 1)
        #expect(counts.count(of: .overOneYear) == 1)
        #expect(counts.count(of: .over1GB) == 1)
        #expect(counts.count(of: .from100MBTo1GB) == 0)
    }

    @Test func offersTheKindsOfTheFilesFoundAndTheChosenOnes() async {
        let viewModel = await scannedViewModel()
        #expect(viewModel.kindOptions == [.archive, .video, .audio])

        viewModel.filter.kinds = [.image]
        #expect(viewModel.kindOptions == [.archive, .video, .audio, .image])
    }

    @Test func stopsOfferingKindsWhoseFilesWereRemoved() async {
        let viewModel = await scannedViewModel()
        viewModel.toggle(song)

        await viewModel.remove()?.value

        #expect(viewModel.kindOptions == [.archive, .video])
    }

    // MARK: Selection

    @Test func selectsNothingAfterTheScan() async {
        let viewModel = await scannedViewModel()

        #expect(!viewModel.hasSelection)
        #expect(viewModel.allSelectionState == .none)
    }

    @Test func togglesSingleFiles() async {
        let viewModel = await scannedViewModel()

        viewModel.toggle(trip)
        viewModel.toggle(song)
        viewModel.toggle(song)

        #expect(viewModel.isSelected(trip))
        #expect(!viewModel.isSelected(song))
        #expect(viewModel.selectedCount == 1)
        #expect(viewModel.selectedSize == 2_000_000_000)
        #expect(viewModel.allSelectionState == .some)
    }

    @Test func selectAllOnlyAffectsVisibleFiles() async {
        let viewModel = await scannedViewModel()
        viewModel.filter.kinds = [.audio, .archive]

        viewModel.toggleAll()

        #expect(viewModel.allSelectionState == .all)
        #expect(Set(viewModel.selectedItems) == [song.item, backup.item])

        viewModel.toggleAll()
        #expect(!viewModel.hasSelection)
    }

    @Test func keepsTheSelectionWhenTheFilterChanges() async {
        let viewModel = await scannedViewModel()
        viewModel.toggle(trip)

        viewModel.filter.kinds = [.audio]

        #expect(viewModel.selectedItems == [trip.item])
        #expect(viewModel.allSelectionState == .none)
    }

    // MARK: Removal

    @Test func movesTheSelectedFilesToTheTrash() async {
        let remover = RecordingRemover()
        let viewModel = await scannedViewModel(remover: remover)
        viewModel.toggle(trip)
        viewModel.toggle(backup)

        await viewModel.remove()?.value

        #expect(Set(remover.removed) == [trip.id, backup.id])
        #expect(report(of: viewModel)?.removedCount == 2)
        #expect(report(of: viewModel)?.freedBytes == 2_300_000_000)
    }

    @Test func doesNothingWithoutASelection() async {
        let remover = RecordingRemover()
        let viewModel = await scannedViewModel(remover: remover)

        #expect(viewModel.remove() == nil)
        #expect(viewModel.phase == .review)
        #expect(remover.removed.isEmpty)
    }

    @Test func doneReturnsToTheListWithoutTheRemovedFiles() async {
        let remover = RecordingRemover(failing: [backup.id])
        let viewModel = await scannedViewModel(remover: remover)
        viewModel.filter.kinds = [.video, .archive]
        viewModel.toggle(trip)
        viewModel.toggle(backup)
        await viewModel.remove()?.value

        viewModel.done()

        #expect(viewModel.phase == .review)
        #expect(viewModel.files == [song, backup])
        #expect(viewModel.visibleFiles == [backup])
        #expect(!viewModel.hasSelection)
    }

    @Test func doneIsIgnoredBeforeFinishing() async {
        let viewModel = await scannedViewModel()

        viewModel.done()

        #expect(viewModel.phase == .review)
        #expect(viewModel.foundCount == 3)
    }
}
