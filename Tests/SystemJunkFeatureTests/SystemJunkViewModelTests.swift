import CleanMacCore
import Foundation
import SystemJunkFeature
import Testing

@MainActor
struct SystemJunkViewModelTests {
    private let item = CleanableItem(url: URL(filePath: "/home/Library/Caches/com.example.app"), size: 42)
    private let remover = RecordingRemover()

    private func scannedViewModel() async -> SystemJunkViewModel {
        let viewModel = SystemJunkViewModel(
            scanService: JunkScanService(scanners: [StubJunkScanner(category: .userCaches, items: [item])]),
            cleanupService: CleanupService(remover: remover)
        )
        await viewModel.startScan().value
        return viewModel
    }

    @Test func askingToCleanRemovesNothing() async {
        let viewModel = await scannedViewModel()

        viewModel.requestClean()

        #expect(viewModel.isConfirmingClean)
        #expect(viewModel.selectedCount == 1)
        #expect(viewModel.phase == .review)
        #expect(remover.removed.isEmpty)
    }

    @Test func asksNothingWithoutASelection() async {
        let viewModel = await scannedViewModel()
        viewModel.toggle(item)

        viewModel.requestClean()

        #expect(!viewModel.isConfirmingClean)
    }

    @Test func cancellingTheCleanupRemovesNothing() async {
        let viewModel = await scannedViewModel()
        viewModel.requestClean()

        viewModel.cancelClean()

        #expect(!viewModel.isConfirmingClean)
        #expect(viewModel.phase == .review)
        #expect(viewModel.hasSelection)
        #expect(remover.removed.isEmpty)
    }

    @Test func confirmingCleansAndStopsAsking() async {
        let viewModel = await scannedViewModel()
        viewModel.requestClean()

        await viewModel.clean()?.value

        #expect(!viewModel.isConfirmingClean)
        #expect(remover.removed == [item.url])
    }

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
