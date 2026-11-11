import CleanMacCore
import Foundation
import LargeFilesFeature
import Testing

struct LargeFileTests {
    @Test func buildsFromARecord() {
        let url = URL(filePath: "/tmp/movie.mov")
        let date = Date(timeIntervalSince1970: 1_000)
        let record = FileRecord(url: url, size: 42, accessDate: nil, modificationDate: date)

        let file = LargeFile(record: record)

        #expect(file.id == url)
        #expect(file.name == "movie.mov")
        #expect(file.item.size == 42)
        #expect(file.kind == .video)
        #expect(file.lastAccessDate == date)
    }
}
