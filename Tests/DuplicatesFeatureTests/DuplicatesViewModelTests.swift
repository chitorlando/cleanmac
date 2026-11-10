import CleanMacCore
import DuplicatesFeature
import Foundation
import Testing

@MainActor
struct DuplicatesViewModelTests {
    private typealias Fixtures = DuplicateFixtures
    private let size = DuplicateFixtures.fileSize

    // Three copies with their own data: keeping the oldest frees two copies' worth of space.
    private let report = Fixtures.file("/Users/test/report.pdf", created: Fixtures.date(1))
    private let reportDownload = Fixtures.file("/Users/test/Downloads/report.pdf", created: Fixtures.date(2))
    private let reportDesktop = Fixtures.file("/Users/test/Desktop/report.pdf", created: Fixtures.date(3))
    // A photo and a clone of it, which share their data, plus a copy with its own data.
    private let photo = Fixtures.file("/Users/test/Pictures/photo.heic", created: Fixtures.date(1), storage: .clone(stream: 1, count: 2))
    private let photoClone = Fixtures.file("/Users/test/Desktop/photo.heic", created: Fixtures.date(2), storage: .clone(stream: 1, count: 2))
    private let photoCopy = Fixtures.file("/Users/test/Downloads/photo.heic", created: Fixtures.date(3))

    private var reports: DuplicateGroup { Fixtures.group(report, reportDownload, reportDesktop) }
    private var photos: DuplicateGroup { Fixtures.group(photo, photoClone, photoCopy) }

    private func makeViewModel(
        events: [DuplicateScanEvent]? = nil,
        finishes: Bool = true,
        remover: any ItemRemoving = RecordingRemover()
    ) -> DuplicatesViewModel {
        let events = events ?? [
            .progress(DuplicateScanProgress(scannedFiles: 500)),
            .found(photos),
            .found(reports),
            .progress(DuplicateScanProgress(scannedFiles: 812, hashedBytes: 30_000_000))
        ]
        return DuplicatesViewModel(
            scanner: StubDuplicateScanner(events: events, finishes: finishes),
            cleanupService: CleanupService(remover: remover)
        )
    }

    private func scannedViewModel(remover: any ItemRemoving = RecordingRemover()) async -> DuplicatesViewModel {
        let viewModel = makeViewModel(remover: remover)
        await viewModel.startScan().value
        return viewModel
    }

    /// Starts a scan that never ends and waits until it has found its first group.
    private func scanningViewModel() async -> (DuplicatesViewModel, Task<Void, Never>) {
        let viewModel = makeViewModel(
            events: [.progress(DuplicateScanProgress(scannedFiles: 500)), .found(reports)],
            finishes: false
        )
        let task = viewModel.startScan()
        while viewModel.groups.isEmpty {
            await Task.yield()
        }
        return (viewModel, task)
    }

    private func report(of viewModel: DuplicatesViewModel) -> CleanupReport? {
        guard case .finished(let report) = viewModel.phase else { return nil }
        return report
    }

    // MARK: Phases and progress

    @Test func startsOnTheIntro() {
        let viewModel = makeViewModel()

        #expect(viewModel.phase == .intro)
        #expect(viewModel.groups.isEmpty)
        #expect(viewModel.progress == DuplicateScanProgress())
    }

    @Test func reportsProgressWhileScanning() async {
        let (viewModel, task) = await scanningViewModel()

        #expect(viewModel.phase == .scanning)
        #expect(viewModel.progress.scannedFiles == 500)
        #expect(viewModel.groups == [reports])
        viewModel.stopScan()
        await task.value
    }

    @Test func reviewsEveryGroupFoundAndFocusesTheFirst() async {
        let viewModel = await scannedViewModel()

        #expect(viewModel.phase == .review)
        #expect(viewModel.groups == [photos, reports])
        #expect(viewModel.progress == DuplicateScanProgress(scannedFiles: 812, hashedBytes: 30_000_000))
        #expect(viewModel.focusedGroup == reports)
        #expect(!viewModel.wasStoppedEarly)
    }

    @Test func countsClonesOnceInTheRecoverableSpace() async {
        let viewModel = await scannedViewModel()

        #expect(photos.recoverableSize == size)
        #expect(reports.recoverableSize == size * 2)
        #expect(viewModel.recoverableSize == size * 3)
    }

    @Test func stoppingTheScanReviewsTheGroupsFoundSoFar() async {
        let (viewModel, task) = await scanningViewModel()

        viewModel.stopScan()
        await task.value

        #expect(viewModel.phase == .review)
        #expect(viewModel.wasStoppedEarly)
        #expect(viewModel.groups == [reports])
        #expect(viewModel.focusedGroup == reports)
    }

    @Test func stoppingIsIgnoredWhenNotScanning() async {
        let viewModel = await scannedViewModel()

        viewModel.stopScan()

        #expect(!viewModel.wasStoppedEarly)
        #expect(viewModel.phase == .review)
    }

    @Test func scanningAgainStartsFromScratch() async {
        let (viewModel, firstScan) = await scanningViewModel()
        viewModel.stopScan()
        await firstScan.value
        viewModel.selectDuplicates()

        let secondScan = viewModel.startScan()

        #expect(viewModel.phase == .scanning)
        #expect(viewModel.groups.isEmpty)
        #expect(!viewModel.hasSelection)
        #expect(!viewModel.wasStoppedEarly)
        #expect(viewModel.focusedGroupID == nil)
        viewModel.stopScan()
        await secondScan.value
    }

    // MARK: Search and order

    @Test func listsTheGroupsThatFreeTheMostSpaceFirst() async {
        let viewModel = await scannedViewModel()

        #expect(viewModel.visibleGroups == [reports, photos])

        viewModel.query.sortOrder = .name
        #expect(viewModel.visibleGroups == [photos, reports])
    }

    @Test func searchesTheGroupsByPath() async {
        let viewModel = await scannedViewModel()

        viewModel.query.searchText = "pictures"

        #expect(viewModel.visibleGroups == [photos])
    }

    // MARK: Selection

    @Test func selectsNothingAfterTheScan() async {
        let viewModel = await scannedViewModel()

        #expect(!viewModel.hasSelection)
        #expect(viewModel.selectedSize == 0)
    }

    @Test func selectingDuplicatesKeepsTheOldestCopyOfEachGroup() async {
        let viewModel = await scannedViewModel()

        viewModel.selectDuplicates()

        #expect(Set(viewModel.selectedItems) == [reportDownload.item, reportDesktop.item, photoCopy.item])
        #expect(viewModel.isSuggestedKeeper(report, in: reports))
        #expect(viewModel.selectionState(of: reports) == .all)
        #expect(viewModel.selectionState(of: photos) == .all)
    }

    @Test func selectingDuplicatesLeavesClonesOfTheKeptCopy() async {
        let viewModel = await scannedViewModel()

        viewModel.selectDuplicates()

        #expect(viewModel.isSuggestedKeeper(photo, in: photos))
        #expect(!viewModel.isSelected(photoClone))
        #expect(viewModel.selectedSize == size * 3)
    }

    @Test func selectingDuplicatesOnlyAffectsVisibleGroups() async {
        let viewModel = await scannedViewModel()
        viewModel.query.searchText = "report"

        viewModel.selectDuplicates()

        #expect(Set(viewModel.selectedItems) == [reportDownload.item, reportDesktop.item])
    }

    @Test func neverMarksEveryCopyOfAGroup() async {
        let viewModel = await scannedViewModel()

        viewModel.toggle(reportDownload, in: reports)
        viewModel.toggle(reportDesktop, in: reports)
        viewModel.toggle(report, in: reports)

        #expect(!viewModel.isSelected(report))
        #expect(!viewModel.canSelect(report, in: reports))
        #expect(viewModel.canSelect(reportDesktop, in: reports))
        #expect(viewModel.selectedCount == 2)
    }

    @Test func aCloneOnlyFreesSpaceTogetherWithTheCopiesThatShareItsData() async {
        let viewModel = await scannedViewModel()

        viewModel.toggle(photoClone, in: photos)
        #expect(viewModel.selectedCount == 1)
        #expect(viewModel.selectedSize == 0)

        viewModel.toggle(photo, in: photos)
        #expect(viewModel.selectedSize == size)
    }

    @Test func togglesWholeGroups() async {
        let viewModel = await scannedViewModel()

        viewModel.toggle(photos)
        #expect(Set(viewModel.selectedItems) == [photoCopy.item])

        viewModel.toggle(photos)
        #expect(!viewModel.hasSelection)
    }

    @Test func copiesOfAGroupOfClonesCanBeMarkedByHandButNeverAll() async {
        let first = Fixtures.file("/Users/test/a.zip", created: Fixtures.date(1), storage: .clone(stream: 9, count: 3))
        let second = Fixtures.file("/Users/test/b/a.zip", created: Fixtures.date(2), storage: .clone(stream: 9, count: 3))
        let third = Fixtures.file("/Users/test/c/a.zip", created: Fixtures.date(3), storage: .clone(stream: 9, count: 3))
        let clones = Fixtures.group(first, second, third)
        let viewModel = makeViewModel(events: [.found(clones)])
        await viewModel.startScan().value

        viewModel.toggle(first, in: clones)
        viewModel.toggle(second, in: clones)
        viewModel.toggle(third, in: clones)

        #expect(viewModel.isSelected(first) && viewModel.isSelected(second))
        #expect(!viewModel.isSelected(third))
        #expect(!viewModel.canSelect(third, in: clones))
        #expect(viewModel.selectedCount == 2)
        #expect(viewModel.selectedSize == 0)
    }

    @Test func markingAGroupOfClonesKeepsTheSuggestedCopy() async {
        let first = Fixtures.file("/Users/test/a.zip", created: Fixtures.date(1), storage: .clone(stream: 9, count: 2))
        let second = Fixtures.file("/Users/test/b/a.zip", created: Fixtures.date(2), storage: .clone(stream: 9, count: 2))
        let clones = Fixtures.group(first, second)
        let viewModel = makeViewModel(events: [.found(clones), .found(reports)])
        await viewModel.startScan().value

        viewModel.toggle(clones)
        #expect(viewModel.selectedItems.map(\.id) == [second.id])
        #expect(viewModel.selectionState(of: clones) == .all)

        viewModel.toggle(clones)
        #expect(!viewModel.hasSelection)
    }

    @Test func selectingDuplicatesLeavesGroupsOfClonesAlone() async {
        let clones = Fixtures.group(
            Fixtures.file("/Users/test/a.zip", storage: .clone(stream: 9, count: 2)),
            Fixtures.file("/Users/test/b/a.zip", storage: .clone(stream: 9, count: 2))
        )
        let viewModel = makeViewModel(events: [.found(clones), .found(reports)])
        await viewModel.startScan().value

        viewModel.toggleDuplicates()

        #expect(Set(viewModel.selectedItems.map(\.id)) == [reportDownload.id, reportDesktop.id])
        #expect(viewModel.selectionState(of: clones) == .none)
    }

    @Test func theSelectDuplicatesCheckboxMarksOrClearsTheVisibleGroups() async {
        let viewModel = await scannedViewModel()
        #expect(viewModel.duplicatesSelectionState == .none)

        viewModel.toggle(reportDesktop, in: reports)
        #expect(viewModel.duplicatesSelectionState == .some)

        viewModel.toggleDuplicates()
        #expect(viewModel.duplicatesSelectionState == .all)
        #expect(Set(viewModel.selectedItems.map(\.id)) == [reportDownload.id, reportDesktop.id, photoCopy.id])

        viewModel.toggleDuplicates()
        #expect(viewModel.duplicatesSelectionState == .none)
        #expect(!viewModel.hasSelection)
    }

    @Test func theSelectDuplicatesCheckboxIgnoresGroupsWithNothingToMark() async {
        let clones = Fixtures.group(
            Fixtures.file("/Users/test/a.zip", storage: .clone(stream: 9, count: 2)),
            Fixtures.file("/Users/test/b/a.zip", storage: .clone(stream: 9, count: 2))
        )
        let viewModel = makeViewModel(events: [.found(clones), .found(reports)])
        await viewModel.startScan().value

        viewModel.toggleDuplicates()
        #expect(viewModel.duplicatesSelectionState == .all)

        viewModel.query.searchText = "a.zip"
        #expect(viewModel.duplicatesSelectionState == .none)
        #expect(!viewModel.canToggleDuplicates)
    }

    @Test func clearingTheVisibleGroupsKeepsTheOthersMarked() async {
        let viewModel = await scannedViewModel()
        viewModel.selectDuplicates()
        viewModel.query.searchText = "photo"

        viewModel.toggleDuplicates()

        #expect(Set(viewModel.selectedItems.map(\.id)) == [reportDownload.id, reportDesktop.id])
    }

    // MARK: Removal

    @Test func movesTheSelectedCopiesToTheTrash() async {
        let remover = RecordingRemover()
        let viewModel = await scannedViewModel(remover: remover)
        viewModel.selectDuplicates()

        await viewModel.remove()?.value

        #expect(Set(remover.removed) == [reportDownload.id, reportDesktop.id, photoCopy.id])
        #expect(report(of: viewModel)?.removedCount == 3)
        #expect(report(of: viewModel)?.freedBytes == size * 3)
    }

    @Test func theReportCountsTheSpaceOfClonesOnce() async {
        let older = Fixtures.file("/Users/test/a.mov", created: Fixtures.date(1))
        let clone = Fixtures.file("/Users/test/Desktop/a.mov", created: Fixtures.date(2), storage: .clone(stream: 5, count: 2))
        let otherClone = Fixtures.file("/Users/test/Movies/a.mov", created: Fixtures.date(3), storage: .clone(stream: 5, count: 2))
        let viewModel = makeViewModel(events: [.found(Fixtures.group(older, clone, otherClone))])
        await viewModel.startScan().value
        viewModel.selectDuplicates()

        #expect(viewModel.selectedCount == 2)
        #expect(viewModel.selectedSize == size)
        await viewModel.remove()?.value

        #expect(report(of: viewModel)?.removedCount == 2)
        #expect(report(of: viewModel)?.freedBytes == size)
    }

    @Test func doesNothingWithoutASelection() async {
        let remover = RecordingRemover()
        let viewModel = await scannedViewModel(remover: remover)

        #expect(viewModel.remove() == nil)
        #expect(viewModel.phase == .review)
        #expect(remover.removed.isEmpty)
    }

    @Test func doneReturnsToTheListWithoutTheRemovedCopies() async {
        let remover = RecordingRemover(failing: [reportDesktop.id])
        let viewModel = await scannedViewModel(remover: remover)
        viewModel.selectDuplicates()
        await viewModel.remove()?.value

        viewModel.done()

        #expect(viewModel.phase == .review)
        #expect(viewModel.groups.map(\.files) == [[photo, photoClone], [report, reportDesktop]])
        #expect(viewModel.focusedGroupID == reports.id)
        #expect(!viewModel.hasSelection)
    }

    @Test func doneIsIgnoredBeforeFinishing() async {
        let viewModel = await scannedViewModel()

        viewModel.done()

        #expect(viewModel.phase == .review)
        #expect(viewModel.groups.count == 2)
    }

    @Test func restartingDuringARemovalIgnoresItsResult() async {
        let gated = GatedRemover()
        let viewModel = await scannedViewModel(remover: gated)
        viewModel.selectDuplicates()

        let removal = viewModel.remove()
        await gated.waitUntilRemoving()
        await viewModel.startScan().value
        await gated.open()
        await removal?.value

        #expect(viewModel.phase == .review)
        #expect(viewModel.groups == [photos, reports])
    }
}
