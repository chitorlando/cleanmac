@testable import CleanMacCore
import Foundation
import Testing

struct FallbackItemRemoverTests {
    private struct UnrelatedError: Error {}

    /// Records the URLs it receives and then throws the configured error, if any.
    private actor SpyRemover: ItemRemoving {
        private let error: (any Error)?
        private(set) var removedURLs: [URL] = []

        init(throwing error: (any Error)? = nil) {
            self.error = error
        }

        func remove(_ url: URL) async throws {
            removedURLs.append(url)
            if let error { throw error }
        }
    }

    private let url = URL(filePath: "/Applications/Protected.app")

    @Test func doesNotCallFallbackWhenPrimarySucceeds() async throws {
        let primary = SpyRemover()
        let fallback = SpyRemover()

        try await FallbackItemRemover(primary: primary, fallback: fallback).remove(url)

        #expect(await primary.removedURLs == [url])
        #expect(await fallback.removedURLs.isEmpty)
    }

    @Test func usesFallbackWhenPrimaryIsDeniedPermission() async throws {
        let primary = SpyRemover(throwing: CocoaError(.fileWriteNoPermission))
        let fallback = SpyRemover()

        try await FallbackItemRemover(primary: primary, fallback: fallback).remove(url)

        #expect(await fallback.removedURLs == [url])
    }

    @Test func rethrowsOtherErrorsWithoutFallback() async {
        let primary = SpyRemover(throwing: CocoaError(.fileNoSuchFile))
        let fallback = SpyRemover()

        await #expect(throws: CocoaError.self) {
            try await FallbackItemRemover(primary: primary, fallback: fallback).remove(url)
        }
        #expect(await fallback.removedURLs.isEmpty)
    }

    @Test func reportsTheFallbackErrorWhenBothFail() async {
        let primary = SpyRemover(throwing: CocoaError(.fileWriteNoPermission))
        let fallback = SpyRemover(throwing: UnrelatedError())

        await #expect(throws: UnrelatedError.self) {
            try await FallbackItemRemover(primary: primary, fallback: fallback).remove(url)
        }
    }
}
