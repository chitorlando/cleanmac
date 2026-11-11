import CleanMacUI
import MonitorFeature
import Testing

@MainActor
struct MonitorModuleTests {
    @Test func appearsAmongThePerformanceFeatures() {
        let module = MonitorModule(viewModel: MonitorViewModel(sampler: FakeSampler([])))

        #expect(module.id == "monitor")
        #expect(module.section == .performance)
        #expect(!module.title.isEmpty)
        #expect(!module.symbolName.isEmpty)
    }
}
