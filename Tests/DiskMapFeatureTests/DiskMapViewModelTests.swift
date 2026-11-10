import CleanMacCore
import Combine
import DiskMapFeature
import Foundation
import Testing

@MainActor
struct DiskMapViewModelTests {
    private typealias Fixtures = DiskMapFixtures

    private func url(_ path: String) -> URL { Fixtures.home.appending(path: path) }

    private func makeViewModel(
        events: [DiskMapScanEvent]? = nil,
        finishes: Bool = true,
        remover: RecordingRemover = RecordingRemover()
    ) -> DiskMapViewModel {
        let events = events ?? [.progress(DiskMapProgress(fileCount: 6, byteCount: 906)), .finished(Fixtures.map)]
        return DiskMapViewModel(
            scanner: StubDiskMapScanner(events: events, finishes: finishes),
            cleanupService: CleanupService(remover: remover),
            policy: DiskMapRemovalPolicy(home: Fixtures.home)
        )
    }

    private func scannedViewModel(remover: RecordingRemover = RecordingRemover()) async -> DiskMapViewModel {
        let viewModel = makeViewModel(remover: remover)
        await viewModel.startScan().value
        return viewModel
    }

    private func item(_ name: String, in viewModel: DiskMapViewModel) throws -> DiskNode {
        try #require(viewModel.items.first { $0.name == name })
    }

    // MARK: Phases

    @Test func startsOnTheIntro() {
        let viewModel = makeViewModel()

        #expect(viewModel.phase == .intro)
        #expect(viewModel.map == nil)
        #expect(viewModel.items.isEmpty)
    }

    @Test func reportsFilesAndBytesWhileScanning() async {
        let progress = DiskMapProgress(fileCount: 500, byteCount: 2_000_000)
        let viewModel = makeViewModel(events: [.progress(progress)], finishes: false)

        let task = viewModel.startScan()
        while viewModel.progress != progress {
            await Task.yield()
        }

        #expect(viewModel.phase == .scanning)
        viewModel.stopScan()
        await task.value
    }

    @Test func showsTheMapOnceTheScanEnds() async {
        let viewModel = await scannedViewModel()

        #expect(viewModel.phase == .map)
        #expect(viewModel.map == Fixtures.map)
        #expect(viewModel.focusedFolder == Fixtures.map)
        #expect(viewModel.items.map(\.name) == ["Movies", "Library", "Tool.app", "notes.txt"])
        #expect(!viewModel.segments.isEmpty)
    }

    @Test func goesBackToTheStartWhenTheScanIsStopped() async {
        let viewModel = makeViewModel(events: [.progress(DiskMapProgress(fileCount: 1, byteCount: 1))], finishes: false)

        let task = viewModel.startScan()
        viewModel.stopScan()
        await task.value

        #expect(viewModel.phase == .intro)
        #expect(viewModel.map == nil)
    }

    @Test func ignoresTheResultOfACancelledScan() async {
        let viewModel = makeViewModel()
        let first = viewModel.startScan()
        first.cancel()
        await first.value

        #expect(viewModel.phase == .scanning)
        #expect(viewModel.map == nil)
    }

    // MARK: Browsing

    @Test func opensFoldersAndKeepsTheirBreadcrumbs() async throws {
        let viewModel = await scannedViewModel()

        viewModel.open(try item("Movies", in: viewModel))
        viewModel.open(try item("Trips", in: viewModel))

        #expect(viewModel.breadcrumbs.map(\.name) == ["test", "Movies", "Trips"])
        #expect(viewModel.items.map(\.name) == ["beach.mov"])
        #expect(viewModel.canGoUp)
    }

    @Test func goesUpAndHighlightsTheFolderItLeft() async throws {
        let viewModel = await scannedViewModel()
        viewModel.open(try item("Movies", in: viewModel))

        viewModel.goUp()

        #expect(viewModel.focusedFolder == Fixtures.map)
        #expect(viewModel.highlightedID == url("Movies"))
        #expect(!viewModel.canGoUp)
    }

    @Test func jumpsToABreadcrumb() async throws {
        let viewModel = await scannedViewModel()
        viewModel.open(try item("Movies", in: viewModel))
        viewModel.open(try item("Trips", in: viewModel))

        viewModel.goToBreadcrumb(at: 1)

        #expect(viewModel.breadcrumbs.map(\.name) == ["test", "Movies"])
    }

    @Test func opensOnlyFoldersWithSomethingInside() async throws {
        let viewModel = await scannedViewModel()

        viewModel.open(try item("notes.txt", in: viewModel))
        viewModel.open(try item("Tool.app", in: viewModel))

        #expect(viewModel.focusPath.isEmpty)
    }

    // MARK: Highlight

    @Test func announcesTheHighlightOnlyWhenItChanges() async {
        let viewModel = await scannedViewModel()
        var announcements = 0
        let observation = viewModel.objectWillChange.sink { announcements += 1 }

        viewModel.highlightedID = url("Movies")
        viewModel.highlightedID = url("Movies")
        #expect(announcements == 1)

        viewModel.highlightedID = url("notes.txt")
        viewModel.highlightedID = nil
        viewModel.highlightedID = nil
        #expect(announcements == 3)
        #expect(viewModel.highlightedID == nil)
        observation.cancel()
    }

    // MARK: Keyboard

    @Test func movesTheHighlightThroughTheItems() async {
        let viewModel = await scannedViewModel()

        viewModel.moveHighlight(by: 1)
        #expect(viewModel.highlightedID == url("Movies"))
        viewModel.moveHighlight(by: 2)
        #expect(viewModel.highlightedID == url("Applications/Tool.app"))
        viewModel.moveHighlight(by: 5)
        #expect(viewModel.highlightedID == url("notes.txt"))
        viewModel.moveHighlight(by: -9)
        #expect(viewModel.highlightedID == url("Movies"))
    }

    @Test func startsFromTheEndWhenMovingUp() async {
        let viewModel = await scannedViewModel()

        viewModel.moveHighlight(by: -1)

        #expect(viewModel.highlightedID == url("notes.txt"))
    }

    @Test func opensTheHighlightedFolder() async {
        let viewModel = await scannedViewModel()
        viewModel.moveHighlight(by: 1)

        viewModel.openHighlighted()

        #expect(viewModel.breadcrumbs.map(\.name) == ["test", "Movies"])
    }

    // MARK: Selection

    @Test func selectsOnlyWhatThePolicyAllows() async throws {
        let viewModel = await scannedViewModel()
        let library = try item("Library", in: viewModel)
        let app = try item("Tool.app", in: viewModel)
        let notes = try item("notes.txt", in: viewModel)

        viewModel.toggle(library)
        viewModel.toggle(app)
        viewModel.toggle(notes)

        #expect(!viewModel.canSelect(library))
        #expect(viewModel.advice(for: app) == .useUninstaller)
        #expect(viewModel.selectedItems.map(\.url) == [notes.url])
    }

    @Test func selectsInSeveralFolders() async throws {
        let viewModel = await scannedViewModel()
        viewModel.toggle(try item("notes.txt", in: viewModel))
        viewModel.open(try item("Library", in: viewModel))
        viewModel.open(try item("Caches", in: viewModel))
        viewModel.toggle(try item("com.example", in: viewModel))

        #expect(Set(viewModel.selectedItems.map(\.url)) == [url("notes.txt"), url("Library/Caches/com.example")])
        #expect(viewModel.selectedSize == 180)
        #expect(viewModel.selectedCount == 2)
    }

    @Test func leavesItemsInsideASelectedFolderToIt() async throws {
        let viewModel = await scannedViewModel()
        viewModel.open(try item("Movies", in: viewModel))
        let trips = try item("Trips", in: viewModel)
        viewModel.open(trips)
        viewModel.toggle(try item("beach.mov", in: viewModel))
        viewModel.goUp()

        viewModel.toggle(trips)

        #expect(viewModel.selectedItems.map(\.url) == [url("Movies/Trips")])
        #expect(viewModel.selectedSize == 400)
    }

    @Test func keepsStandardFoldersOutOfTheSelection() async throws {
        let viewModel = await scannedViewModel()
        let movies = try item("Movies", in: viewModel)

        viewModel.toggle(movies)

        #expect(viewModel.advice(for: movies) == .standardFolder)
        #expect(!viewModel.hasSelection)
    }

    // MARK: Removal

    @Test func movesTheSelectionToTheTrashAndShrinksTheMap() async throws {
        let remover = RecordingRemover()
        let viewModel = await scannedViewModel(remover: remover)
        viewModel.open(try item("Movies", in: viewModel))
        viewModel.toggle(try item("Trips", in: viewModel))

        await viewModel.remove()?.value

        #expect(remover.removed == [url("Movies/Trips")])
        guard case .finished(let report) = viewModel.phase else {
            Issue.record("Expected the finished phase")
            return
        }
        #expect(report.freedBytes == 400)
        #expect(viewModel.map?.size == Fixtures.map.size - 400)
        #expect(viewModel.items.map(\.name) == ["clip.mov"])
        #expect(!viewModel.hasSelection)

        viewModel.done()
        #expect(viewModel.phase == .map)
    }

    @Test func keepsWhatCouldNotBeRemoved() async throws {
        let remover = RecordingRemover(failing: [url("notes.txt")])
        let viewModel = await scannedViewModel(remover: remover)
        viewModel.toggle(try item("notes.txt", in: viewModel))

        await viewModel.remove()?.value

        #expect(viewModel.items.contains { $0.name == "notes.txt" })
        #expect(viewModel.map?.size == Fixtures.map.size)
    }

    @Test func climbsOutOfAFolderThatWasRemoved() async throws {
        let viewModel = await scannedViewModel()
        viewModel.open(try item("Movies", in: viewModel))
        let trips = try item("Trips", in: viewModel)
        viewModel.toggle(trips)
        viewModel.open(trips)

        await viewModel.remove()?.value

        #expect(viewModel.focusPath == [url("Movies")])
        #expect(viewModel.items.map(\.name) == ["clip.mov"])
    }

    @Test func doesNothingWithoutASelection() async {
        let viewModel = await scannedViewModel()

        #expect(viewModel.remove() == nil)
        #expect(viewModel.phase == .map)
    }
}
