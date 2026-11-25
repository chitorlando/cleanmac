import CleanMacCore
import CleanMacUI
import DuplicatesFeature
import Foundation
import Testing

@MainActor
struct DuplicatesModuleTests {
    private let downloads = URL(filePath: "/Users/test/Downloads")

    /// A module with its view model and its scanner, which refuses the folders given.
    private func makeModule(
        refusing refusedFolders: Set<URL> = []
    ) -> (DuplicatesModule, DuplicatesViewModel, StubDuplicateScanner) {
        let scanner = StubDuplicateScanner(events: [], refusedFolders: refusedFolders)
        let viewModel = DuplicatesViewModel(
            scanner: scanner,
            cleanupService: CleanupService(remover: RecordingRemover())
        )
        return (DuplicatesModule(viewModel: viewModel), viewModel, scanner)
    }

    @Test func offersToFindDuplicatesInAFolder() throws {
        let (module, _, _) = makeModule()

        #expect(module.itemActions.count == 1)
        let action = try #require(module.itemActions.first)
        #expect(action.featureID == module.id)
        #expect(action.itemKind == .folder)
        #expect(action.symbolName == "doc.on.doc")
        #expect(!action.title.isEmpty)
    }

    @Test func scansTheFolderItIsOpenedWith() async {
        let (module, viewModel, scanner) = makeModule()

        module.show(itemAt: downloads)

        #expect(viewModel.scope == .folder(downloads))
        while viewModel.phase == .scanning {
            await Task.yield()
        }
        #expect(viewModel.phase == .review)
        #expect(scanner.scannedScopes == [.folder(downloads)])
    }

    @Test func ignoresAnItemItCannotScan() {
        let (module, viewModel, scanner) = makeModule(refusing: [downloads])

        module.show(itemAt: downloads)

        #expect(viewModel.phase == .intro)
        #expect(viewModel.scope == .home)
        #expect(scanner.scannedScopes.isEmpty)
    }

    /// Other features offer its action only for the folders it would scan.
    @Test func takesOnlyTheFoldersTheScanOfTheHomeEnters() throws {
        let home = try TemporaryFolder()
        let documents = try home.makeFolder("Documents")
        let caches = try home.makeFolder("Library/Caches")
        let excludedDirectories = [home.root.appending(path: "Library")]
        let scanner = DuplicateScanner(
            home: home.root,
            walker: FileSystemWalker(excludedDirectories: excludedDirectories),
            excludedDirectories: excludedDirectories
        )
        let module = DuplicatesModule(
            viewModel: DuplicatesViewModel(scanner: scanner, cleanupService: CleanupService(remover: RecordingRemover()))
        )

        #expect(module.canShow(itemAt: documents))
        #expect(module.canShow(itemAt: home.root))
        #expect(!module.canShow(itemAt: caches))
        #expect(!module.canShow(itemAt: home.root.appending(path: "Library")))
    }
}
