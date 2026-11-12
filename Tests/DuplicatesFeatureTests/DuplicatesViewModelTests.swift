import CleanMacCore
import Combine
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

    // Folders of the stub scanner's home folder that another feature can ask for.
    private let downloads = URL(filePath: "/Users/test/Downloads")
    private let pictures = URL(filePath: "/Users/test/Pictures")

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

    /// The groups aren't `@Published`, so the view model announces their changes itself.
    /// Each number is how many groups there were when a change was announced.
    @Test func announcesEveryChangeToTheGroupsBeforeMakingIt() async {
        let viewModel = makeViewModel(events: [.found(photos), .found(reports)])
        var groupCounts: [Int] = []
        let observation = viewModel.objectWillChange.sink { groupCounts.append(viewModel.groups.count) }

        await viewModel.startScan().value
        // Clearing the groups, the selection, the progress, the warning and the focus, and
        // starting; then each group found, the focus on the first group and the review.
        #expect(groupCounts == [0, 0, 0, 0, 0, 0, 0, 1, 2, 2])

        viewModel.toggle(reportDownload, in: reports)
        viewModel.toggle(reportDesktop, in: reports)
        groupCounts = []
        await viewModel.remove()?.value
        // Removing, the groups left, the selection, the focus on the group left and the report.
        #expect(groupCounts == [2, 2, 1, 1, 1])
        #expect(viewModel.groups == [photos])
        observation.cancel()
    }

    @Test func countsClonesOnceInTheRecoverableSpace() async {
        let viewModel = await scannedViewModel()

        #expect(photos.recoverableSize == size)
        #expect(reports.recoverableSize == size * 2)
        #expect(viewModel.recoverableSize == size * 3)
    }

    @Test func theFocusedGroupFollowsTheFocus() async {
        let viewModel = await scannedViewModel()
        #expect(viewModel.focusedGroup == reports)

        viewModel.focusedGroupID = photos.id

        #expect(viewModel.focusedGroup == photos)
    }

    @Test func derivedValuesFollowTheGroupsLeftAfterARemoval() async {
        let viewModel = await scannedViewModel()
        viewModel.focusedGroupID = photos.id
        viewModel.toggle(photoCopy, in: photos)
        #expect(viewModel.visibleGroups == [reports, photos])
        #expect(viewModel.recoverableSize == size * 3)
        #expect(viewModel.focusedGroup == photos)
        #expect(viewModel.selectedCount == 1)

        await viewModel.remove()?.value

        let remainingPhotos = Fixtures.group(photo, photoClone)
        #expect(viewModel.visibleGroups == [reports, remainingPhotos])
        #expect(viewModel.recoverableSize == size * 2)
        #expect(viewModel.focusedGroup == remainingPhotos)
        #expect(!viewModel.hasSelection)
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

    @Test func writingTheSameQueryAgainKeepsTheListAndANewOneUpdatesIt() async {
        let viewModel = await scannedViewModel()
        viewModel.query.searchText = "pictures"
        #expect(viewModel.visibleGroups == [photos])

        viewModel.query.searchText = "pictures"
        #expect(viewModel.visibleGroups == [photos])

        viewModel.query.searchText = ""
        #expect(viewModel.visibleGroups == [reports, photos])
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

    @Test func promisesNoSpaceForClonesThatCannotBeCounted() async {
        let own = Fixtures.file("/Users/test/a.mov", created: Fixtures.date(1))
        let clone = Fixtures.file("/Users/test/Desktop/a.mov", created: Fixtures.date(2), storage: .uncountedClone(stream: 5))
        let otherClone = Fixtures.file("/Users/test/Movies/a.mov", created: Fixtures.date(3), storage: .uncountedClone(stream: 5))
        let group = Fixtures.group(own, clone, otherClone)
        let viewModel = makeViewModel(events: [.found(group)])
        await viewModel.startScan().value

        #expect(viewModel.recoverableSize == size)
        viewModel.selectDuplicates()
        #expect(viewModel.selectedItems.map(\.id) == [own.id])
        #expect(viewModel.selectedSize == size)

        viewModel.toggle(own, in: group)
        viewModel.toggle(clone, in: group)
        viewModel.toggle(otherClone, in: group)
        #expect(viewModel.selectedCount == 2)
        #expect(viewModel.selectedSize == 0)
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

    // MARK: Scanning one folder

    /// A view model and its scanner, which tells what it was asked to scan and finds the
    /// photos and the reports whatever the scope.
    private func makeScopedViewModel(
        finishes: Bool = true,
        refusing refusedFolders: Set<URL> = [],
        remover: any ItemRemoving = RecordingRemover()
    ) -> (DuplicatesViewModel, StubDuplicateScanner) {
        let scanner = StubDuplicateScanner(
            events: [.found(photos), .found(reports)],
            finishes: finishes,
            refusedFolders: refusedFolders
        )
        let viewModel = DuplicatesViewModel(scanner: scanner, cleanupService: CleanupService(remover: remover))
        return (viewModel, scanner)
    }

    /// A view model on the report of a removal that followed a scan of the home folder.
    private func finishedViewModel() async -> (DuplicatesViewModel, StubDuplicateScanner) {
        let (viewModel, scanner) = makeScopedViewModel()
        await viewModel.startScan().value
        viewModel.selectDuplicates()
        await viewModel.remove()?.value
        return (viewModel, scanner)
    }

    @Test func scansTheWholeHomeFolderUnlessAskedForAFolder() async {
        let (viewModel, scanner) = makeScopedViewModel()
        #expect(viewModel.scope == .home)

        await viewModel.startScan().value

        #expect(viewModel.scope == .home)
        #expect(scanner.scannedScopes == [.home])
    }

    @Test func aFolderIsScannedAtOnceFromTheIntro() async {
        let (viewModel, scanner) = makeScopedViewModel()

        let scan = viewModel.scanFolder(at: downloads)

        #expect(viewModel.phase == .scanning)
        #expect(viewModel.scope == .folder(downloads))
        await scan?.value
        #expect(viewModel.phase == .review)
        #expect(viewModel.groups == [photos, reports])
        #expect(scanner.scannedScopes == [.folder(downloads)])
    }

    @Test func aFolderReplacesTheScanInProgress() async {
        let (viewModel, scanner) = makeScopedViewModel(finishes: false)
        let homeScan = viewModel.startScan()
        while viewModel.groups.count < 2 {
            await Task.yield()
        }

        let folderScan = viewModel.scanFolder(at: downloads)

        #expect(viewModel.phase == .scanning)
        #expect(viewModel.scope == .folder(downloads))
        #expect(viewModel.groups.isEmpty)
        await homeScan.value
        while viewModel.groups.count < 2 {
            await Task.yield()
        }
        #expect(viewModel.phase == .scanning)
        #expect(scanner.scannedScopes == [.home, .folder(downloads)])
        viewModel.stopScan()
        await folderScan?.value
    }

    @Test func aFolderReplacesTheResultsOnScreen() async {
        let (viewModel, scanner) = makeScopedViewModel()
        await viewModel.startScan().value
        viewModel.selectDuplicates()
        viewModel.query.searchText = "photo"

        await viewModel.scanFolder(at: downloads)?.value

        #expect(viewModel.phase == .review)
        #expect(viewModel.scope == .folder(downloads))
        #expect(scanner.scannedScopes == [.home, .folder(downloads)])
        #expect(!viewModel.hasSelection)
        #expect(viewModel.query.searchText.isEmpty)
        #expect(viewModel.visibleGroups == [reports, photos])
    }

    @Test func anotherFolderReplacesTheFolderOnScreen() async {
        let (viewModel, scanner) = makeScopedViewModel()
        await viewModel.scanFolder(at: downloads)?.value
        viewModel.query.searchText = "photo"

        await viewModel.scanFolder(at: pictures)?.value

        #expect(viewModel.scope == .folder(pictures))
        #expect(scanner.scannedScopes == [.folder(downloads), .folder(pictures)])
        #expect(viewModel.query.searchText.isEmpty)
    }

    @Test func scanningAgainStaysInTheFolderAndKeepsTheSearch() async {
        let (viewModel, scanner) = makeScopedViewModel()
        await viewModel.scanFolder(at: downloads)?.value
        viewModel.query.searchText = "photo"

        await viewModel.startScan().value

        #expect(viewModel.scope == .folder(downloads))
        #expect(scanner.scannedScopes == [.folder(downloads), .folder(downloads)])
        #expect(viewModel.query.searchText == "photo")
        #expect(viewModel.visibleGroups == [photos])
    }

    @Test func askingForTheFolderOnScreenScansItAgainAndKeepsTheSearch() async {
        let (viewModel, scanner) = makeScopedViewModel()
        await viewModel.scanFolder(at: downloads)?.value
        viewModel.selectDuplicates()
        viewModel.query.searchText = "photo"

        await viewModel.scanFolder(at: downloads)?.value

        #expect(scanner.scannedScopes == [.folder(downloads), .folder(downloads)])
        #expect(!viewModel.hasSelection)
        #expect(viewModel.query.searchText == "photo")
    }

    @Test func scanningTheHomeFolderLeavesTheFolder() async {
        let (viewModel, scanner) = makeScopedViewModel()
        await viewModel.scanFolder(at: downloads)?.value
        viewModel.query.searchText = "photo"

        await viewModel.scanHome().value

        #expect(viewModel.phase == .review)
        #expect(viewModel.scope == .home)
        #expect(scanner.scannedScopes == [.folder(downloads), .home])
        #expect(viewModel.query.searchText.isEmpty)
    }

    @Test func stoppingAFolderScanStaysInTheFolder() async {
        let (viewModel, _) = makeScopedViewModel(finishes: false)
        let scan = viewModel.scanFolder(at: downloads)
        while viewModel.groups.isEmpty {
            await Task.yield()
        }

        viewModel.stopScan()
        await scan?.value

        #expect(viewModel.phase == .review)
        #expect(viewModel.wasStoppedEarly)
        #expect(viewModel.scope == .folder(downloads))
    }

    @Test func theHomeFolderAskedForAsAFolderIsScannedWhole() async {
        let (viewModel, scanner) = makeScopedViewModel()
        await viewModel.scanFolder(at: downloads)?.value

        await viewModel.scanFolder(at: StubDuplicateScanner.home)?.value

        #expect(viewModel.scope == .home)
        #expect(scanner.scannedScopes == [.folder(downloads), .home])
    }

    @Test func aFolderAskedForDuringARemovalWaitsForItsReport() async {
        let gated = GatedRemover()
        let (viewModel, scanner) = makeScopedViewModel(remover: gated)
        await viewModel.startScan().value
        viewModel.selectDuplicates()
        let removal = viewModel.remove()
        await gated.waitUntilRemoving()

        #expect(viewModel.scanFolder(at: downloads) == nil)

        #expect(viewModel.phase == .removing)
        #expect(viewModel.scope == .home)
        await gated.open()
        await removal?.value
        #expect(report(of: viewModel)?.removedCount == 3)
        #expect(viewModel.scope == .home)
        #expect(scanner.scannedScopes == [.home])

        await viewModel.done()?.value

        #expect(viewModel.phase == .review)
        #expect(viewModel.scope == .folder(downloads))
        #expect(scanner.scannedScopes == [.home, .folder(downloads)])
        #expect(viewModel.groups == [photos, reports])
    }

    @Test func aFolderAskedForOnTheReportIsScannedWhenLeavingIt() async {
        let (viewModel, scanner) = await finishedViewModel()

        #expect(viewModel.scanFolder(at: downloads) == nil)
        #expect(report(of: viewModel)?.removedCount == 3)
        #expect(scanner.scannedScopes == [.home])

        let scan = viewModel.done()

        #expect(viewModel.phase == .scanning)
        #expect(viewModel.scope == .folder(downloads))
        await scan?.value
        #expect(scanner.scannedScopes == [.home, .folder(downloads)])
    }

    @Test func theLastFolderAskedForDuringARemovalWins() async {
        let (viewModel, scanner) = await finishedViewModel()
        viewModel.scanFolder(at: downloads)
        viewModel.scanFolder(at: pictures)

        await viewModel.done()?.value

        #expect(viewModel.scope == .folder(pictures))
        #expect(scanner.scannedScopes == [.home, .folder(pictures)])
    }

    @Test func aFolderLeftForLaterIsOnlyScannedOnce() async {
        let (viewModel, scanner) = await finishedViewModel()
        viewModel.scanFolder(at: downloads)
        await viewModel.done()?.value
        viewModel.selectDuplicates()
        await viewModel.remove()?.value

        #expect(viewModel.done() == nil)

        #expect(viewModel.phase == .review)
        #expect(scanner.scannedScopes == [.home, .folder(downloads)])
    }

    @Test func aFolderThatCanNoLongerBeScannedIsDroppedWhenLeavingTheReport() async {
        let (viewModel, scanner) = await finishedViewModel()
        viewModel.scanFolder(at: downloads)
        scanner.refuse(downloads)

        #expect(viewModel.done() == nil)

        #expect(viewModel.phase == .review)
        #expect(viewModel.scope == .home)
        #expect(scanner.scannedScopes == [.home])
    }

    @Test func aNewScanForgetsTheFolderLeftForLater() async {
        let gated = GatedRemover()
        let (viewModel, scanner) = makeScopedViewModel(remover: gated)
        await viewModel.startScan().value
        viewModel.selectDuplicates()
        let removal = viewModel.remove()
        await gated.waitUntilRemoving()
        viewModel.scanFolder(at: downloads)

        await viewModel.startScan().value
        await gated.open()
        await removal?.value
        viewModel.selectDuplicates()
        await viewModel.remove()?.value

        #expect(viewModel.done() == nil)
        #expect(viewModel.scope == .home)
        #expect(scanner.scannedScopes == [.home, .home])
    }

    @Test func ignoresAFolderThatCannotBeScannedOnItsOwn() async {
        let (viewModel, scanner) = makeScopedViewModel(refusing: [downloads])

        #expect(viewModel.scanFolder(at: downloads) == nil)

        #expect(viewModel.phase == .intro)
        #expect(viewModel.scope == .home)
        #expect(scanner.scannedScopes.isEmpty)
    }

    @Test func aFolderThatCannotBeScannedLeavesTheScanInProgressAlone() async {
        let (viewModel, scanner) = makeScopedViewModel(finishes: false, refusing: [downloads])
        let scan = viewModel.scanFolder(at: pictures)
        while viewModel.groups.count < 2 {
            await Task.yield()
        }

        #expect(viewModel.scanFolder(at: downloads) == nil)

        #expect(viewModel.phase == .scanning)
        #expect(viewModel.scope == .folder(pictures))
        #expect(viewModel.groups == [photos, reports])
        #expect(scanner.scannedScopes == [.folder(pictures)])
        viewModel.stopScan()
        await scan?.value
    }

    @Test func aFolderThatCannotBeScannedLeavesTheResultsAlone() async {
        let (viewModel, scanner) = makeScopedViewModel(refusing: [downloads])
        await viewModel.scanFolder(at: pictures)?.value
        viewModel.selectDuplicates()
        viewModel.query.searchText = "photo"

        #expect(viewModel.scanFolder(at: downloads) == nil)

        #expect(viewModel.phase == .review)
        #expect(viewModel.scope == .folder(pictures))
        #expect(viewModel.selectedCount == 3)
        #expect(viewModel.query.searchText == "photo")
        #expect(scanner.scannedScopes == [.folder(pictures)])
    }

    @Test func aFolderThatCannotBeScannedIsNotLeftForLater() async {
        let (viewModel, scanner) = await finishedViewModel()
        scanner.refuse(downloads)
        viewModel.scanFolder(at: downloads)

        #expect(viewModel.done() == nil)

        #expect(viewModel.phase == .review)
        #expect(scanner.scannedScopes == [.home])
    }
}
