import CleanMacCore
import CleanMacUI
import Foundation
import SystemJunkFeature
import Testing

@MainActor
struct SystemJunkModuleTests {
    private let home = URL(filePath: "/Users/test")
    private let item = CleanableItem(url: URL(filePath: "/Users/test/Library/Caches/com.example.app"), size: 42)

    private func makeViewModel() -> SystemJunkViewModel {
        SystemJunkViewModel(
            scanService: JunkScanService(scanners: [StubJunkScanner(category: .userCaches, items: [item])]),
            cleanupService: CleanupService(remover: BlockingRemover()),
            trashEmptying: TrashEmptyingService(emptier: RecordingTrashEmptier()),
            runningApps: FakeRunningApps(),
            cacheUsage: BrowserCacheUsage(library: home.appending(path: "Library"))
        )
    }

    private func makeModule(viewModel: SystemJunkViewModel? = nil) -> SystemJunkModule {
        SystemJunkModule(viewModel: viewModel ?? makeViewModel(), junkFolders: JunkCatalog.locations(home: home))
    }

    @Test func offersOneActionForFolders() {
        let actions = makeModule().itemActions

        // The id of an action is the id of its feature and the kind of item it takes.
        #expect(actions.map(\.id) == ["system-junk.folder"])
        #expect(actions.allSatisfy { !$0.title.isEmpty && !$0.symbolName.isEmpty })
    }

    @Test func takesOnlyTheFoldersWhoseJunkItCleans() {
        let module = makeModule()

        #expect(module.canShow(itemAt: home.appending(path: "Library/Caches")))
        #expect(module.canShow(itemAt: home.appending(path: "Library/Caches", directoryHint: .isDirectory)))
        #expect(module.canShow(itemAt: home.appending(path: "Library/Logs")))
        #expect(module.canShow(itemAt: home.appending(path: "Library/Developer/Xcode/DerivedData")))
        #expect(!module.canShow(itemAt: home.appending(path: "Library/Caches/com.example.app")))
        #expect(!module.canShow(itemAt: home.appending(path: "Library")))
        #expect(!module.canShow(itemAt: home.appending(path: "Documents")))
    }

    @Test func takesNoFolderWithoutJunkFolders() {
        let module = SystemJunkModule(viewModel: makeViewModel())

        #expect(!module.canShow(itemAt: home.appending(path: "Library/Caches")))
    }

    @Test func showingAFolderLooksForJunkFirst() async {
        let viewModel = makeViewModel()
        let module = makeModule(viewModel: viewModel)

        module.show(itemAt: home.appending(path: "Library/Caches"))

        #expect(viewModel.phase == .scanning)
        while viewModel.phase == .scanning {
            await Task.yield()
        }
        #expect(viewModel.phase == .review)
        #expect(viewModel.results.flatMap(\.items) == [item])
    }

    /// What the user chose to clean stays as it was.
    @Test func showingAFolderKeepsTheJunkAlreadyFound() async {
        let viewModel = makeViewModel()
        let module = makeModule(viewModel: viewModel)
        await viewModel.startScan().value
        viewModel.toggle(item)

        module.show(itemAt: home.appending(path: "Library/Caches"))

        #expect(viewModel.phase == .review)
        #expect(viewModel.results.flatMap(\.items) == [item])
        #expect(!viewModel.isSelected(item))
    }
}
