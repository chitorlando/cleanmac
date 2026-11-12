import CleanMacCore
import Foundation
import Testing

struct MissingItemTolerantRemoverTests {
    private struct UnrelatedError: Error {}

    /// Throws the configured error, if any, for every URL.
    private struct FailingRemover: ItemRemoving {
        let error: (any Error)?

        func remove(_ url: URL) async throws {
            if let error { throw error }
        }
    }

    private let url = URL(filePath: "/tmp/item")

    @Test func takesAnItemThatIsAlreadyGoneAsRemoved() async throws {
        try await MissingItemTolerantRemover(FailingRemover(error: CocoaError(.fileNoSuchFile))).remove(url)
    }

    @Test func rethrowsOtherErrors() async {
        await #expect(throws: UnrelatedError.self) {
            try await MissingItemTolerantRemover(FailingRemover(error: UnrelatedError())).remove(url)
        }
    }

    /// Nothing reaches the Trash: the item doesn't exist.
    @Test func takesAnItemTheTrashCannotFindAsRemoved() async throws {
        let missing = FileManager.default.temporaryDirectory.appending(path: "missing-\(UUID().uuidString)")

        try await MissingItemTolerantRemover(TrashItemRemover()).remove(missing)
    }
}
