import CleanMacCore
import Foundation
import LargeFilesFeature
import Testing

/// The size found, the visible files, the filter counts, the selected items and the "select
/// all" state are kept between reads, so every test reads them before a change and checks
/// that they follow it.
@MainActor
struct LargeFilesViewModelDerivedStateTests {
    private typealias Fixtures = LargeFileFixtures

    private let trip = Fixtures.file("trip.mov", megabytes: 2_000, lastUsed: Fixtures.date(2024, 1, 1))
    private let song = Fixtures.file("song.mp3", megabytes: 60, lastUsed: Fixtures.date(2026, 11, 1))
    private let backup = Fixtures.file("backup.zip", megabytes: 300, lastUsed: Fixtures.date(2026, 8, 1))

    private func makeViewModel(
        remover: RecordingRemover = RecordingRemover(),
        now: @escaping () -> Date = { Fixtures.now }
    ) -> LargeFilesViewModel {
        LargeFilesViewModel(
            scanner: StubLargeFileScanner(events: [song, trip, backup].map { .found($0) }),
            cleanupService: CleanupService(remover: remover),
            now: now,
            calendar: Fixtures.calendar
        )
    }

    private func scannedViewModel(
        remover: RecordingRemover = RecordingRemover(),
        now: @escaping () -> Date = { Fixtures.now }
    ) async -> LargeFilesViewModel {
        let viewModel = makeViewModel(remover: remover, now: now)
        await viewModel.startScan().value
        return viewModel
    }

    // MARK: Files

    @Test func everyValueFollowsTheFilesFound() async {
        let viewModel = makeViewModel()
        #expect(viewModel.foundSize == 0)
        #expect(viewModel.visibleFiles.isEmpty)
        #expect(viewModel.filterCounts.count(of: .video) == 0)
        #expect(viewModel.selectedItems.isEmpty)
        #expect(viewModel.allSelectionState == .none)

        await viewModel.startScan().value

        #expect(viewModel.foundSize == 2_360_000_000)
        #expect(viewModel.visibleFiles == [trip, backup, song])
        #expect(viewModel.filterCounts.count(of: .video) == 1)
        viewModel.toggleAll()
        #expect(viewModel.selectedItems == [song.item, trip.item, backup.item])
        #expect(viewModel.allSelectionState == .all)
    }

    /// The screen can't tick a file before it's listed, but the selected items come from the
    /// files, so they must follow them even then.
    @Test func everyValueFollowsEachFileFoundDuringTheScan() async {
        let scanner = ManualLargeFileScanner()
        let viewModel = LargeFilesViewModel(
            scanner: scanner,
            cleanupService: CleanupService(remover: RecordingRemover()),
            now: { Fixtures.now },
            calendar: Fixtures.calendar
        )
        let scan = viewModel.startScan()
        viewModel.toggle(trip)
        #expect(viewModel.foundSize == 0)
        #expect(viewModel.visibleFiles.isEmpty)
        #expect(viewModel.filterCounts.count(of: .video) == 0)
        #expect(viewModel.selectedItems.isEmpty)
        #expect(viewModel.allSelectionState == .none)

        scanner.send(.found(trip))
        while viewModel.foundCount < 1 {
            await Task.yield()
        }
        #expect(viewModel.foundSize == 2_000_000_000)
        #expect(viewModel.visibleFiles == [trip])
        #expect(viewModel.filterCounts.count(of: .video) == 1)
        #expect(viewModel.selectedItems == [trip.item])
        #expect(viewModel.allSelectionState == .all)

        scanner.send(.found(song))
        while viewModel.foundCount < 2 {
            await Task.yield()
        }
        #expect(viewModel.foundSize == 2_060_000_000)
        #expect(viewModel.visibleFiles == [trip, song])
        #expect(viewModel.filterCounts.count(of: .audio) == 1)
        #expect(viewModel.selectedItems == [trip.item])
        #expect(viewModel.allSelectionState == .some)

        scanner.finish()
        await scan.value
    }

    @Test func everyValueFollowsTheFilesLeftAfterARemoval() async {
        let viewModel = await scannedViewModel(remover: RecordingRemover(failing: [backup.id]))
        viewModel.toggle(trip)
        viewModel.toggle(backup)
        #expect(viewModel.foundSize == 2_360_000_000)
        #expect(viewModel.visibleFiles == [trip, backup, song])
        #expect(viewModel.filterCounts.count(of: .video) == 1)
        #expect(viewModel.selectedItems == [trip.item, backup.item])
        #expect(viewModel.allSelectionState == .some)

        await viewModel.remove()?.value

        #expect(viewModel.foundSize == 360_000_000)
        #expect(viewModel.visibleFiles == [backup, song])
        #expect(viewModel.filterCounts.count(of: .video) == 0)
        #expect(viewModel.filterCounts.count(of: .archive) == 1)
        #expect(viewModel.selectedItems.isEmpty)
        #expect(viewModel.allSelectionState == .none)
    }

    @Test func scanningAgainStartsFromAnEmptyList() async {
        let viewModel = await scannedViewModel()
        viewModel.toggleAll()
        #expect(viewModel.foundSize == 2_360_000_000)
        #expect(viewModel.visibleFiles.count == 3)
        #expect(viewModel.filterCounts.count(of: .audio) == 1)
        #expect(viewModel.selectedCount == 3)
        #expect(viewModel.allSelectionState == .all)

        let scan = viewModel.startScan()
        #expect(viewModel.foundSize == 0)
        #expect(viewModel.visibleFiles.isEmpty)
        #expect(viewModel.filterCounts.count(of: .audio) == 0)
        #expect(!viewModel.hasSelection)
        #expect(viewModel.allSelectionState == .none)

        await scan.value
        #expect(viewModel.foundSize == 2_360_000_000)
        #expect(viewModel.visibleFiles.count == 3)
        #expect(viewModel.filterCounts.count(of: .audio) == 1)
    }

    // MARK: Order

    @Test func visibleFilesFollowTheOrder() async {
        let viewModel = await scannedViewModel()
        #expect(viewModel.visibleFiles == [trip, backup, song])

        viewModel.sortOrder = .name
        #expect(viewModel.visibleFiles == [backup, song, trip])

        viewModel.sortOrder = .lastAccess
        #expect(viewModel.visibleFiles == [trip, backup, song])

        viewModel.sortOrder = .size
        #expect(viewModel.visibleFiles == [trip, backup, song])
    }

    @Test func filteredFilesKeepTheChosenOrder() async {
        let viewModel = await scannedViewModel()
        viewModel.sortOrder = .name
        #expect(viewModel.visibleFiles == [backup, song, trip])

        viewModel.filter.kinds = [.video, .archive]
        #expect(viewModel.visibleFiles == [backup, trip])

        viewModel.sortOrder = .size
        #expect(viewModel.visibleFiles == [trip, backup])
    }

    // MARK: Filter

    @Test func visibleFilesFollowEveryConditionOfTheFilter() async {
        let viewModel = await scannedViewModel()
        #expect(viewModel.visibleFiles == [trip, backup, song])

        viewModel.filter.kinds = [.audio, .archive]
        #expect(viewModel.visibleFiles == [backup, song])

        viewModel.filter.ageBucket = .oneToSixMonths
        #expect(viewModel.visibleFiles == [backup])

        viewModel.filter.ageBucket = nil
        viewModel.filter.sizeBucket = .upTo100MB
        #expect(viewModel.visibleFiles == [song])

        viewModel.filter = LargeFileFilter(searchText: "tri")
        #expect(viewModel.visibleFiles == [trip])

        viewModel.filter.searchText = ""
        #expect(viewModel.visibleFiles == [trip, backup, song])
    }

    @Test func filterCountsFollowEveryConditionOfTheFilter() async {
        let viewModel = await scannedViewModel()
        #expect(viewModel.filterCounts.count(of: .lessThanOneMonth) == 1)
        #expect(viewModel.filterCounts.count(of: .audio) == 1)

        viewModel.filter.kinds = [.video]
        #expect(viewModel.filterCounts.count(of: .lessThanOneMonth) == 0)
        #expect(viewModel.filterCounts.count(of: .over1GB) == 1)

        viewModel.filter.ageBucket = .overOneYear
        #expect(viewModel.filterCounts.count(of: .audio) == 0)
        #expect(viewModel.filterCounts.count(of: .video) == 1)

        viewModel.filter = LargeFileFilter(sizeBucket: .from100MBTo1GB)
        #expect(viewModel.filterCounts.count(of: .video) == 0)
        #expect(viewModel.filterCounts.count(of: .archive) == 1)

        viewModel.filter = LargeFileFilter(searchText: "song")
        #expect(viewModel.filterCounts.count(of: .archive) == 0)
        #expect(viewModel.filterCounts.count(of: .audio) == 1)
    }

    // MARK: Selection

    @Test func selectionTotalsFollowEveryToggle() async {
        let viewModel = await scannedViewModel()
        #expect(!viewModel.hasSelection)
        #expect(viewModel.allSelectionState == .none)

        viewModel.toggle(trip)
        #expect(viewModel.selectedItems == [trip.item])
        #expect(viewModel.selectedSize == 2_000_000_000)
        #expect(viewModel.allSelectionState == .some)

        viewModel.toggle(song)
        viewModel.toggle(backup)
        #expect(viewModel.selectedCount == 3)
        #expect(viewModel.selectedSize == 2_360_000_000)
        #expect(viewModel.allSelectionState == .all)

        viewModel.toggle(trip)
        #expect(viewModel.selectedItems == [song.item, backup.item])
        #expect(viewModel.allSelectionState == .some)

        viewModel.toggleAll()
        viewModel.toggleAll()
        #expect(!viewModel.hasSelection)
        #expect(viewModel.allSelectionState == .none)
    }

    @Test func selectAllFollowsTheFilter() async {
        let viewModel = await scannedViewModel()
        viewModel.toggle(trip)
        #expect(viewModel.allSelectionState == .some)

        viewModel.filter.kinds = [.video]
        #expect(viewModel.allSelectionState == .all)

        viewModel.filter = LargeFileFilter(searchText: "song")
        #expect(viewModel.allSelectionState == .none)
    }

    @Test func selectAllIsTheSameInAnyOrder() async {
        let viewModel = await scannedViewModel()
        viewModel.toggle(trip)
        #expect(viewModel.allSelectionState == .some)

        viewModel.sortOrder = .name

        #expect(viewModel.allSelectionState == .some)
        #expect(viewModel.selectedItems == [trip.item])
    }

    // MARK: Clock

    @Test func groupingByAgeFollowsTheClock() async {
        var today = Fixtures.now
        let viewModel = await scannedViewModel(now: { today })
        viewModel.filter.ageBucket = .lessThanOneMonth
        viewModel.toggle(song)
        #expect(viewModel.visibleFiles == [song])
        #expect(viewModel.filterCounts.count(of: .lessThanOneMonth) == 1)
        #expect(viewModel.filterCounts.count(of: .oneToSixMonths) == 1)
        #expect(viewModel.allSelectionState == .all)

        today = Fixtures.date(2026, 12, 15)

        #expect(viewModel.allSelectionState == .none)
        #expect(viewModel.visibleFiles.isEmpty)
        #expect(viewModel.filterCounts.count(of: .lessThanOneMonth) == 0)
        #expect(viewModel.filterCounts.count(of: .oneToSixMonths) == 2)
        #expect(viewModel.selectedItems == [song.item])
    }

    @Test func groupingByAgeFollowsAClockSetBack() async {
        var today = Fixtures.now
        let viewModel = await scannedViewModel(now: { today })
        viewModel.filter.ageBucket = .lessThanOneMonth
        #expect(viewModel.visibleFiles == [song])
        #expect(viewModel.filterCounts.count(of: .lessThanOneMonth) == 1)

        today = Fixtures.date(2026, 8, 15)

        #expect(viewModel.visibleFiles == [backup, song])
        #expect(viewModel.filterCounts.count(of: .lessThanOneMonth) == 2)
    }
}
