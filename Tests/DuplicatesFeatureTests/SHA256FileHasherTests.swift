import CryptoKit
import DuplicatesFeature
import Foundation
import Testing

struct SHA256FileHasherTests {
    private let content = Data.pattern(count: 10_000, seed: 3)

    @Test func hashesTheWholeFileInChunks() throws {
        let folder = try TemporaryFolder()
        let url = try folder.write(content, to: "file.bin")

        let hash = try SHA256FileHasher(chunkSize: 1_024).hash(of: url, upTo: nil)

        #expect(hash.digest == Data(SHA256.hash(data: content)))
        #expect(hash.bytesRead == 10_000)
    }

    @Test func hashesOnlyTheFirstBytesWhenLimited() throws {
        let folder = try TemporaryFolder()
        let url = try folder.write(content, to: "file.bin")

        let hash = try SHA256FileHasher(chunkSize: 1_000).hash(of: url, upTo: 2_500)

        #expect(hash.digest == Data(SHA256.hash(data: content.prefix(2_500))))
        #expect(hash.bytesRead == 2_500)
    }

    @Test func throwsForMissingFiles() {
        let missing = URL(filePath: "/nonexistent/\(UUID().uuidString)")
        #expect(throws: (any Error).self) {
            try SHA256FileHasher().hash(of: missing, upTo: nil)
        }
    }
}
