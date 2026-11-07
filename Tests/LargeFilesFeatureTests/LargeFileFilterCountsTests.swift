import Foundation
import LargeFilesFeature
import Testing

struct LargeFileFilterCountsTests {
    private typealias Fixtures = LargeFileFixtures

    private let files = [
        Fixtures.file("trip.mov", megabytes: 2_000, lastUsed: Fixtures.date(2024, 1, 1)),
        Fixtures.file("talk.mov", megabytes: 70, lastUsed: Fixtures.date(2026, 11, 1)),
        Fixtures.file("photo.heic", megabytes: 60, lastUsed: Fixtures.date(2026, 11, 1)),
        Fixtures.file("old.dmg", megabytes: 500, lastUsed: nil)
    ]

    private func counts(_ filter: LargeFileFilter) -> LargeFileFilterCounts {
        LargeFileFilterCounts(files: files, filter: filter, now: Fixtures.now, calendar: Fixtures.calendar)
    }

    @Test func countsEveryOptionWithoutFilter() {
        let counts = counts(LargeFileFilter())

        #expect(counts.count(of: .video) == 2)
        #expect(counts.count(of: .image) == 1)
        #expect(counts.count(of: .audio) == 0)
        #expect(counts.count(of: .lessThanOneMonth) == 2)
        #expect(counts.count(of: .overOneYear) == 1)
        #expect(counts.count(of: .from50MBTo100MB) == 2)
        #expect(counts.count(of: .over1GB) == 1)
    }

    @Test func eachGroupIgnoresItsOwnCondition() {
        let counts = counts(LargeFileFilter(kinds: [.video]))

        #expect(counts.count(of: .image) == 1)
        #expect(counts.count(of: .lessThanOneMonth) == 1)
        #expect(counts.count(of: .from50MBTo100MB) == 1)
    }

    @Test func appliesTheOtherConditions() {
        let counts = counts(LargeFileFilter(sizeBucket: .over1GB, searchText: "T"))

        #expect(counts.count(of: .video) == 1)
        #expect(counts.count(of: .image) == 0)
        #expect(counts.count(of: .overOneYear) == 1)
        #expect(counts.count(of: .lessThanOneMonth) == 0)
        #expect(counts.count(of: .from50MBTo100MB) == 2)
    }
}
