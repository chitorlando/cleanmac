import CleanMacCore
import CleanMacUI
import Testing
import UninstallerFeature

@MainActor
struct UninstallerModuleTests {
    private func makeModule() -> UninstallerModule {
        let viewModel = UninstallerViewModel(
            scanner: StubAppScanner(events: []),
            runningApps: FakeRunningApps(),
            cleanupService: CleanupService(remover: RecordingRemover())
        )
        return UninstallerModule(viewModel: viewModel)
    }

    @Test func offersToShowTheAppsOtherFeaturesList() throws {
        let module = makeModule()

        let action = try #require(module.itemActions.first)
        #expect(module.itemActions.count == 1)
        #expect(action.featureID == module.id)
        #expect(action.itemKind == .app)
        #expect(!action.title.isEmpty)
        #expect(action.symbolName == module.symbolName)
    }
}
