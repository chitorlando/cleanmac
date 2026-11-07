import CleanMacCore
import Foundation
import LargeFilesFeature
import Testing

struct LargeFileCriteriaTests {
    private let cutoff = Date(timeIntervalSince1970: 1_000_000)

    private func record(size: Int64, lastUsed: Date?) -> FileRecord {
        FileRecord(url: URL(filePath: "/tmp/file"), size: size, accessDate: lastUsed, modificationDate: nil)
    }

    @Test func defaultsToFiftyMegabytesWithoutAgeLimit() {
        let criteria = LargeFileCriteria()
        #expect(criteria.minimumSize == 50_000_000)
        #expect(criteria.olderThan == nil)
    }

    @Test func matchesFilesFromTheMinimumSizeUp() {
        let criteria = LargeFileCriteria(minimumSize: 100)
        #expect(!criteria.matches(record(size: 99, lastUsed: nil)))
        #expect(criteria.matches(record(size: 100, lastUsed: nil)))
    }

    @Test func matchesOnlyFilesLastUsedBeforeTheCutoff() {
        let criteria = LargeFileCriteria(minimumSize: 1, olderThan: cutoff)
        #expect(criteria.matches(record(size: 10, lastUsed: cutoff.addingTimeInterval(-1))))
        #expect(!criteria.matches(record(size: 10, lastUsed: cutoff)))
    }

    @Test func ignoresFilesWithUnknownDateWhenAnAgeIsRequired() {
        let criteria = LargeFileCriteria(minimumSize: 1, olderThan: cutoff)
        #expect(!criteria.matches(record(size: 10, lastUsed: nil)))
    }
}
