import Foundation
import CleanMacCore
import Testing

struct FileRecordTests {
    private let url = URL(filePath: "/tmp/movie.mov")
    private let accessed = Date(timeIntervalSince1970: 2_000)
    private let modified = Date(timeIntervalSince1970: 1_000)

    @Test func prefersTheAccessDate() {
        let record = FileRecord(url: url, size: 1, accessDate: accessed, modificationDate: modified)
        #expect(record.lastAccessDate == accessed)
    }

    @Test func fallsBackToTheModificationDate() {
        let record = FileRecord(url: url, size: 1, accessDate: nil, modificationDate: modified)
        #expect(record.lastAccessDate == modified)
    }
}
