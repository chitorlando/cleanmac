@testable import DiskMapFeature
import Foundation
import Testing

@MainActor
struct DiskMapKeyActionTests {
    private typealias Fixtures = DiskMapFixtures

    private func url(_ path: String) -> URL { Fixtures.home.appending(path: path) }

    private func scannedViewModel() async -> DiskMapViewModel {
        let viewModel = DiskMapViewModel(
            scanner: StubDiskMapScanner(events: [.finished(Fixtures.map)]),
            policy: DiskMapRemovalPolicy(home: Fixtures.home)
        )
        await viewModel.startScan().value
        return viewModel
    }

    @Test func movesTheHighlightDownAndUp() async {
        let viewModel = await scannedViewModel()

        viewModel.perform(.moveHighlight(by: 1))
        viewModel.perform(.moveHighlight(by: 1))
        #expect(viewModel.highlightedID == url("Library"))

        viewModel.perform(.moveHighlight(by: -1))
        #expect(viewModel.highlightedID == url("Movies"))
    }

    @Test func opensTheHighlightedFolder() async {
        let viewModel = await scannedViewModel()
        viewModel.perform(.moveHighlight(by: 1))

        viewModel.perform(.openHighlighted)

        #expect(viewModel.breadcrumbs.map(\.name) == ["test", "Movies"])
    }

    @Test func goesUpToTheFolderAbove() async {
        let viewModel = await scannedViewModel()
        viewModel.perform(.moveHighlight(by: 1))
        viewModel.perform(.openHighlighted)

        viewModel.perform(.goUp)

        #expect(viewModel.breadcrumbs.map(\.name) == ["test"])
        #expect(viewModel.highlightedID == url("Movies"))
    }
}
