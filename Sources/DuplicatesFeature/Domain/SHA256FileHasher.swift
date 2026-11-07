import CryptoKit
import Foundation

/// `FileHashing` with SHA-256, reading the file in chunks so large files never load whole into memory.
public struct SHA256FileHasher: FileHashing {
    public static let defaultChunkSize = 1 << 20

    private let chunkSize: Int

    public init(chunkSize: Int = defaultChunkSize) {
        self.chunkSize = max(1, chunkSize)
    }

    public func hash(of url: URL, upTo limit: Int64?) throws -> FileHash {
        let handle = try FileHandle(forReadingFrom: url)
        defer { try? handle.close() }

        var hasher = SHA256()
        var bytesRead: Int64 = 0
        while let count = nextChunkSize(afterReading: bytesRead, limit: limit) {
            try Task.checkCancellation()
            let chunkLength = try autoreleasepool {
                guard let chunk = try handle.read(upToCount: count), !chunk.isEmpty else { return 0 }
                hasher.update(data: chunk)
                return chunk.count
            }
            guard chunkLength > 0 else { break }
            bytesRead += Int64(chunkLength)
        }
        return FileHash(digest: Data(hasher.finalize()), bytesRead: bytesRead)
    }

    /// How many bytes to read next, or `nil` once the limit is reached.
    private func nextChunkSize(afterReading bytesRead: Int64, limit: Int64?) -> Int? {
        guard let limit else { return chunkSize }
        let remaining = limit - bytesRead
        return remaining > 0 ? Int(min(Int64(chunkSize), remaining)) : nil
    }
}
