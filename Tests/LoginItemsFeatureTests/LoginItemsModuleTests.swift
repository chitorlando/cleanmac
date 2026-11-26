import CleanMacCore
import CleanMacUI
import Foundation
import LoginItemsFeature
import Testing

@MainActor
struct LoginItemsModuleTests {
    private let agent = loginItem("com.example.mine.agent", owner: "Mine")
    private let other = loginItem("com.example.other", owner: "Other")

    private func makeViewModel() -> LoginItemsViewModel {
        LoginItemsViewModel(
            scanner: StubLoginItemScanner(items: [agent, other]),
            cleanupService: CleanupService(remover: RecordingRemover()),
            settingsOpener: SpySettingsOpener()
        )
    }

    @Test func offersToShowTheLoginItemsOfTheAppsOtherFeaturesList() throws {
        let module = LoginItemsModule(viewModel: makeViewModel())

        let action = try #require(module.itemActions.first)
        #expect(module.itemActions.count == 1)
        #expect(action.featureID == module.id)
        #expect(action.itemKind == .app)
        #expect(!action.title.isEmpty)
        #expect(action.symbolName == module.symbolName)
    }

    @Test func takesAppsWithoutReadingTheLoginItems() {
        let viewModel = makeViewModel()
        let module = LoginItemsModule(viewModel: viewModel)

        #expect(module.canShow(itemAt: URL(filePath: "/Applications/Without Items.app")))
        #expect(!module.canShow(itemAt: URL(filePath: "/Applications")))
        #expect(viewModel.phase == .intro)
    }

    @Test func showsOnlyTheLoginItemsOfTheApp() async {
        let viewModel = makeViewModel()
        let module = LoginItemsModule(viewModel: viewModel)
        await viewModel.startLoading().value

        module.show(itemAt: URL(filePath: "/Applications/Mine.app"))

        #expect(viewModel.items == [agent])
    }
}
