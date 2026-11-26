import CleanMacCore
import Foundation
import LoginItemsFeature
import Testing

@MainActor
struct LoginItemsAppFilterTests {
    private let agent = loginItem("com.example.mine.agent", owner: "Mine")
    private let daemon = loginItem("com.example.mine.daemon", scope: .allUsers, owner: "Mine")
    private let other = loginItem("com.example.other", owner: "Other")
    private let unowned = loginItem("com.example.unowned")
    private let mineApp = URL(filePath: "/Applications/Mine.app")

    private func makeViewModel() -> LoginItemsViewModel {
        LoginItemsViewModel(
            scanner: StubLoginItemScanner(items: [other, agent, unowned, daemon]),
            cleanupService: CleanupService(remover: RecordingRemover()),
            settingsOpener: SpySettingsOpener()
        )
    }

    private func loadedViewModel() async -> LoginItemsViewModel {
        let viewModel = makeViewModel()
        await viewModel.startLoading().value
        return viewModel
    }

    @Test func listsOnlyTheItemsOfTheApp() async {
        let viewModel = await loadedViewModel()

        #expect(viewModel.showItems(ofAppAt: mineApp) == nil)

        #expect(viewModel.phase == .browsing)
        #expect(viewModel.appFilter == LoginItemOwner(appURL: mineApp, name: "Mine"))
        #expect(Set(viewModel.items) == [agent, daemon])
        #expect(viewModel.sections.map(\.scope) == [.currentUser, .allUsers])
    }

    @Test func readsTheItemsFirstWhenTheyWereNotRead() async {
        let viewModel = makeViewModel()

        await viewModel.showItems(ofAppAt: mineApp)?.value

        #expect(viewModel.phase == .browsing)
        #expect(Set(viewModel.items) == [agent, daemon])
    }

    @Test func findsTheAppWhateverWayItsPathIsWritten() async {
        let viewModel = await loadedViewModel()

        viewModel.showItems(ofAppAt: URL(filePath: "/Applications/Tools/../Mine.app/"))

        #expect(Set(viewModel.items) == [agent, daemon])
        #expect(viewModel.appFilter?.name == "Mine")
    }

    @Test func takesOnlyAppBundles() {
        let viewModel = makeViewModel()

        #expect(viewModel.canShowItems(ofAppAt: mineApp))
        #expect(viewModel.canShowItems(ofAppAt: URL(filePath: "/Applications/Mine.APP/")))
        #expect(!viewModel.canShowItems(ofAppAt: URL(filePath: "/Applications")))
        #expect(!viewModel.canShowItems(ofAppAt: URL(filePath: "/Users/me/notes.txt")))
    }

    @Test func ignoresWhatIsNotAnApp() {
        let viewModel = makeViewModel()

        #expect(viewModel.showItems(ofAppAt: URL(filePath: "/Applications")) == nil)

        #expect(viewModel.phase == .intro)
        #expect(viewModel.appFilter == nil)
    }

    @Test func listsEveryItemAgainWhenTheLimitIsLifted() async {
        let viewModel = await loadedViewModel()
        viewModel.showItems(ofAppAt: mineApp)

        viewModel.showAllItems()

        #expect(viewModel.appFilter == nil)
        #expect(Set(viewModel.items) == [agent, daemon, other, unowned])
    }

    @Test func listsNothingForAnAppWithoutItems() async {
        let viewModel = await loadedViewModel()

        viewModel.showItems(ofAppAt: URL(filePath: "/Applications/Empty.app"))

        #expect(viewModel.phase == .browsing)
        #expect(viewModel.sections.isEmpty)
        #expect(viewModel.appFilter?.name == "Empty")
    }

    @Test func keepsTheLimitWhenListingAgain() async {
        let viewModel = await loadedViewModel()
        viewModel.showItems(ofAppAt: mineApp)

        await viewModel.startLoading().value

        #expect(Set(viewModel.items) == [agent, daemon])
    }

    @Test func removesOnlyTheListedItems() async {
        let remover = RecordingRemover()
        let viewModel = LoginItemsViewModel(
            scanner: StubLoginItemScanner(items: [other, agent]),
            cleanupService: CleanupService(remover: remover),
            settingsOpener: SpySettingsOpener()
        )
        await viewModel.startLoading().value
        viewModel.toggle(other)
        viewModel.toggle(agent)

        viewModel.showItems(ofAppAt: mineApp)
        await viewModel.remove()?.value

        #expect(remover.removed == [agent.plistURL])
    }
}
