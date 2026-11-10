import CleanMacUI
import DiskMapFeature
import Testing

@MainActor
struct DiskMapModuleTests {
    @Test func appearsAmongTheFileFeatures() {
        let module = DiskMapModule(viewModel: DiskMapViewModel(scanner: StubDiskMapScanner(events: [])))

        #expect(module.id == "disk-map")
        #expect(module.symbolName == "chart.pie.fill")
        #expect(module.section == .files)
        #expect(!module.title.isEmpty)
    }
}
