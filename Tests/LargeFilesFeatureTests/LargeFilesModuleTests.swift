import CleanMacCore
import Foundation
import LargeFilesFeature
import Testing

@MainActor
struct LargeFilesModuleTests {
    private let movies = URL(filePath: "/Users/test/Movies")

    private func makeViewModel(scanner: StubLargeFileScanner) -> LargeFilesViewModel {
        LargeFilesViewModel(scanner: scanner, cleanupService: CleanupService(remover: RecordingRemover()))
    }

    @Test func offersOneActionForFolders() {
        let module = LargeFilesModule(viewModel: makeViewModel(scanner: StubLargeFileScanner(events: [])))

        let actions = module.itemActions

        // The id of an action is the id of its feature and the kind of item it takes.
        #expect(actions.map(\.id) == ["large-files.folder"])
        #expect(actions.allSatisfy { !$0.title.isEmpty && !$0.symbolName.isEmpty })
    }

    @Test func showingAFolderScansOnlyThatFolder() async {
        let scanner = StubLargeFileScanner(events: [])
        let viewModel = makeViewModel(scanner: scanner)
        let module = LargeFilesModule(viewModel: viewModel)

        module.show(itemAt: movies)
        #expect(viewModel.phase == .scanning)
        while viewModel.phase == .scanning {
            await Task.yield()
        }

        #expect(viewModel.scope == .folder(movies))
        #expect(scanner.scannedScopes == [.folder(movies)])
    }

    @Test func showingSomethingTheScannerCannotLookInDoesNothing() {
        let scanner = StubLargeFileScanner(events: [], unscannableFolders: [movies])
        let viewModel = makeViewModel(scanner: scanner)
        let module = LargeFilesModule(viewModel: viewModel)

        module.show(itemAt: movies)

        #expect(viewModel.phase == .intro)
        #expect(scanner.scannedScopes.isEmpty)
    }
}
