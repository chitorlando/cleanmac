@testable import CleanMacCore
import Foundation
import Testing

struct CleanupServiceTests {
    private struct DeniedError: LocalizedError {
        var errorDescription: String? { "Permiso denegado" }
    }

    /// Removes nothing, fails for the configured URLs and doesn't find the missing ones.
    private struct StubRemover: ItemRemoving {
        var failing: Set<URL> = []
        var missing: Set<URL> = []

        func remove(_ url: URL) async throws {
            if failing.contains(url) { throw DeniedError() }
            if missing.contains(url) { throw CocoaError(.fileNoSuchFile) }
        }
    }

    /// Records every URL it is asked to remove.
    private actor RecordingRemover: ItemRemoving {
        private(set) var removedURLs: [URL] = []

        func remove(_ url: URL) async throws {
            removedURLs.append(url)
        }
    }

    @Test func sumsFreedBytesOfRemovedItems() async {
        let items = [
            CleanableItem(url: URL(filePath: "/tmp/a"), size: 100),
            CleanableItem(url: URL(filePath: "/tmp/b"), size: 50)
        ]
        let report = await CleanupService(remover: StubRemover(failing: [])).clean(items)

        #expect(report.freedBytes == 150)
        #expect(report.removedCount == 2)
        #expect(report.failures.isEmpty)
    }

    @Test func keepsGoingAfterAFailure() async {
        let blocked = CleanableItem(url: URL(filePath: "/tmp/blocked"), size: 100)
        let allowed = CleanableItem(url: URL(filePath: "/tmp/ok"), size: 30)
        let service = CleanupService(remover: StubRemover(failing: [blocked.url]))

        let report = await service.clean([blocked, allowed])

        #expect(report.freedBytes == 30)
        #expect(report.failures.map(\.item) == [blocked])
        #expect(report.failures.first?.reason == "Permiso denegado")
    }

    /// Once Privacy removed a cache, System Junk cleaning it too neither fails nor frees it again.
    @Test func skipsItemsThatAreAlreadyGoneWhenAsked() async {
        let gone = CleanableItem(url: URL(filePath: "/tmp/gone"), size: 100)
        let blocked = CleanableItem(url: URL(filePath: "/tmp/blocked"), size: 20)
        let present = CleanableItem(url: URL(filePath: "/tmp/present"), size: 30)
        let remover = StubRemover(failing: [blocked.url], missing: [gone.url])

        let report = await CleanupService(remover: remover, skipsMissingItems: true).clean([gone, blocked, present])

        #expect(report.freedBytes == 30)
        #expect(report.removedCount == 1)
        #expect(report.failures.map(\.item) == [blocked])
    }

    @Test func reportsItemsThatAreAlreadyGoneByDefault() async {
        let gone = CleanableItem(url: URL(filePath: "/tmp/gone"), size: 100)

        let report = await CleanupService(remover: StubRemover(missing: [gone.url])).clean([gone])

        #expect(report.freedBytes == 0)
        #expect(report.removedCount == 0)
        #expect(report.failures.map(\.kind) == [.missing])
    }

    /// Nothing reaches the Trash: the item doesn't exist.
    @Test func skipsAnItemTheTrashCannotFind() async {
        let missing = FileManager.default.temporaryDirectory.appending(path: "missing-\(UUID().uuidString)")
        let service = CleanupService(remover: TrashItemRemover(), skipsMissingItems: true)

        let report = await service.clean([CleanableItem(url: missing, size: 10)])

        #expect(report.freedBytes == 0)
        #expect(report.removedCount == 0)
        #expect(report.failures.isEmpty)
    }

    @Test func removesDuplicatedItemsOnlyOnce() async {
        let shared = CleanableItem(url: URL(filePath: "/tmp/shared"), size: 40)
        let unique = CleanableItem(url: URL(filePath: "/tmp/unique"), size: 10)
        let remover = RecordingRemover()

        let report = await CleanupService(remover: remover).clean([shared, unique, shared])

        #expect(await remover.removedURLs == [shared.url, unique.url])
        #expect(report.removedCount == 2)
        #expect(report.freedBytes == 50)
    }
}
