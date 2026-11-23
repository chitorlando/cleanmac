import CleanMacCore
import CleanMacUI
import MonitorFeature
import Testing

@MainActor
struct MonitorModuleTests {
    private let viewModel = MonitorViewModel(sampler: FakeSampler([]))

    @Test func appearsAmongThePerformanceFeatures() {
        let module = MonitorModule(viewModel: viewModel, preferences: Preferences(storage: InMemoryPreferenceStorage()))

        #expect(module.id == "monitor")
        #expect(module.section == .performance)
        #expect(!module.title.isEmpty)
        #expect(!module.symbolName.isEmpty)
    }

    @Test func readsEveryTwoSecondsUntilTheUserChooses() {
        _ = MonitorModule(viewModel: viewModel, preferences: Preferences(storage: InMemoryPreferenceStorage()))

        #expect(viewModel.interval == .seconds(2))
    }

    @Test func startsWithTheIntervalTheUserChose() {
        let storage = InMemoryPreferenceStorage(["monitor.refreshInterval": 5])
        _ = MonitorModule(viewModel: viewModel, preferences: Preferences(storage: storage))

        #expect(viewModel.interval == .seconds(5))
    }

    @Test func ignoresAnIntervalItDoesNotOffer() {
        let storage = InMemoryPreferenceStorage(["monitor.refreshInterval": 0])
        _ = MonitorModule(viewModel: viewModel, preferences: Preferences(storage: storage))

        #expect(viewModel.interval == .seconds(2))
    }

    @Test func followsTheIntervalTheUserChooses() {
        let preferences = Preferences(storage: InMemoryPreferenceStorage())
        let module = MonitorModule(viewModel: viewModel, preferences: preferences)

        // The view model follows the preferences for as long as its module lives.
        withExtendedLifetime(module) {
            preferences.set(1, for: MonitorSettings.refreshInterval)
            #expect(viewModel.interval == .seconds(1))

            preferences.set(5, for: MonitorSettings.refreshInterval)
            #expect(viewModel.interval == .seconds(5))
        }
    }

    @Test func addsItsIntervalToTheMonitorSettings() {
        let module = MonitorModule(viewModel: viewModel, preferences: Preferences(storage: InMemoryPreferenceStorage()))

        #expect(module.settings.map(\.id) == ["monitor.refreshInterval"])
        #expect(module.settings.map(\.section) == [.monitor])
    }
}
