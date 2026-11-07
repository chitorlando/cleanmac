@testable import CleanMacCore
import Foundation
import Testing

struct CleanupServiceTests {
    private struct DeniedError: LocalizedError {
        var errorDescription: String? { "Permiso denegado" }
    }

    /// Removes nothing and fails for the configured URLs.
    private struct StubRemover: ItemRemoving {
        let failing: Set<URL>

        func remove(_ url: URL) async throws {
            if failing.contains(url) { throw DeniedError() }
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
