import CleanMacCore
import LoginItemsFeature
import Testing

@MainActor
struct LoginItemsViewModelTests {
    private let mine = loginItem("com.example.mine", owner: "Mine")
    private let orphan = loginItem("com.example.orphan", isOrphaned: true)
    private let shared = loginItem("com.example.shared", scope: .allUsers)
    private let remover = RecordingRemover()
    private let opener = SpySettingsOpener()

    private func makeViewModel() -> LoginItemsViewModel {
        LoginItemsViewModel(
            scanner: StubLoginItemScanner(items: [shared, mine, orphan]),
            cleanupService: CleanupService(remover: remover),
            settingsOpener: opener
        )
    }

    private func loadedViewModel() async -> LoginItemsViewModel {
        let viewModel = makeViewModel()
        await viewModel.startLoading().value
        return viewModel
    }

    @Test func startsOnTheIntroduction() {
        #expect(makeViewModel().phase == .intro)
    }

    @Test func listsTheItemsBySectionWithNothingSelected() async {
        let viewModel = await loadedViewModel()

        #expect(viewModel.phase == .browsing)
        #expect(viewModel.sections.map(\.scope) == [.currentUser, .allUsers])
        #expect(viewModel.orphanedCount == 1)
        #expect(!viewModel.hasSelection)
    }

    @Test func selectsOnlyTheUserAgents() async {
        let viewModel = await loadedViewModel()

        viewModel.toggle(mine)
        viewModel.toggle(shared)

        #expect(viewModel.isSelected(mine))
        #expect(!viewModel.isSelected(shared))
        #expect(viewModel.selectedItems == [mine.item])
    }

    @Test func togglesEveryRemovableItemOfASection() async throws {
        let viewModel = await loadedViewModel()
        let userSection = try #require(viewModel.sections.first)
        let sharedSection = try #require(viewModel.sections.last)

        viewModel.toggleAll(in: userSection)
        viewModel.toggleAll(in: sharedSection)

        #expect(viewModel.selectionState(of: userSection) == .all)
        #expect(viewModel.selectionState(of: sharedSection) == .none)
        #expect(viewModel.selectedCount == 2)

        viewModel.toggleAll(in: userSection)
        #expect(!viewModel.hasSelection)
    }

    @Test func movesTheSelectedAgentsToTheTrash() async throws {
        let viewModel = await loadedViewModel()
        viewModel.toggle(orphan)

        await viewModel.remove()?.value

        #expect(remover.removed == [orphan.plistURL])
        guard case .finished(let report) = viewModel.phase else {
            Issue.record("Expected the finished phase, got \(viewModel.phase)")
            return
        }
        #expect(report.removedCount == 1)
    }

    @Test func removesNothingWithoutASelection() async {
        let viewModel = await loadedViewModel()

        #expect(viewModel.remove() == nil)
        #expect(viewModel.phase == .browsing)
    }

    @Test func listsAgainWhenDone() async {
        let viewModel = await loadedViewModel()
        viewModel.toggle(mine)
        await viewModel.remove()?.value

        await viewModel.done().value

        #expect(viewModel.phase == .browsing)
        #expect(!viewModel.hasSelection)
    }

    @Test func opensTheLoginItemsSettings() {
        let viewModel = makeViewModel()

        viewModel.openLoginItemsSettings()

        #expect(opener.openCount == 1)
    }
}
