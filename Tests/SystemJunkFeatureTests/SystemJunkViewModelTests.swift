import CleanMacCore
import Foundation
import SystemJunkFeature
import Testing

@MainActor
struct SystemJunkViewModelTests {
    private let item = CleanableItem(url: URL(filePath: "/home/Library/Caches/com.example.app"), size: 42)

    @Test func restartingDuringACleanupIgnoresItsResult() async {
        let remover = BlockingRemover()
        let viewModel = SystemJunkViewModel(
            scanService: JunkScanService(scanners: [StubJunkScanner(category: .userCaches, items: [item])]),
            cleanupService: CleanupService(remover: remover)
        )
        await viewModel.startScan().value

        let cleanup = viewModel.clean()
        await remover.waitUntilRemoving()
        await viewModel.startScan().value
        remover.release()
        await cleanup?.value

        #expect(viewModel.phase == .review)
    }
}
