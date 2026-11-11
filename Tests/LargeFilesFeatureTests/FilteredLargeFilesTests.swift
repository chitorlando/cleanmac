import Foundation
@testable import LargeFilesFeature
import Testing

struct FilteredLargeFilesTests {
    private typealias Fixtures = LargeFileFixtures

    private let trip = Fixtures.file("trip.mov", megabytes: 2_000, lastUsed: Fixtures.date(2024, 1, 1))
    private let talk = Fixtures.file("talk.mov", megabytes: 70, lastUsed: Fixtures.date(2026, 11, 1))
    private let photo = Fixtures.file("photo.heic", megabytes: 60, lastUsed: Fixtures.date(2026, 11, 1))
    private let installer = Fixtures.file("old.dmg", megabytes: 500, lastUsed: nil)

    private var files: [LargeFile] { [trip, talk, photo, installer] }

    private func filtered(_ filter: LargeFileFilter) -> FilteredLargeFiles {
        let ages = AgeBucketBoundaries(now: Fixtures.now, calendar: Fixtures.calendar)
        return FilteredLargeFiles(files: files, filter: filter, ages: ages)
    }

    @Test func letsEveryFileThroughInTheOrderGivenWithoutConditions() {
        #expect(filtered(LargeFileFilter()).files == files)
    }

    @Test(arguments: [
        LargeFileFilter(kinds: [.video, .diskImage]),
        LargeFileFilter(ageBucket: .lessThanOneMonth),
        LargeFileFilter(sizeBucket: .upTo100MB),
        LargeFileFilter(searchText: " T "),
        LargeFileFilter(kinds: [.video], ageBucket: .lessThanOneMonth, sizeBucket: .upTo100MB, searchText: "talk"),
        LargeFileFilter(kinds: [.audio])
    ])
    func showsTheFilesTheFilterLetsThrough(filter: LargeFileFilter) {
        let expected = filter.apply(to: files, now: Fixtures.now, calendar: Fixtures.calendar)

        #expect(filtered(filter).files == expected)
    }

    @Test func countsEveryOptionWithoutConditions() {
        let counts = filtered(LargeFileFilter()).counts

        #expect(counts.kinds == [.video: 2, .image: 1, .diskImage: 1])
        #expect(counts.ages == [.overOneYear: 1, .lessThanOneMonth: 2])
        #expect(counts.sizes == [.over1GB: 1, .upTo100MB: 2, .from100MBTo1GB: 1])
    }

    @Test func eachGroupOfCountsIgnoresItsOwnCondition() {
        let filter = LargeFileFilter(kinds: [.video], ageBucket: .lessThanOneMonth, sizeBucket: .upTo100MB)

        let result = filtered(filter)

        #expect(result.files == [talk])
        #expect(result.counts.kinds == [.video: 1, .image: 1])
        #expect(result.counts.ages == [.lessThanOneMonth: 1])
        #expect(result.counts.sizes == [.upTo100MB: 1])
    }

    @Test func theCountOfTheOnlyChosenOptionIsTheLengthOfTheList() {
        let result = filtered(LargeFileFilter(ageBucket: .lessThanOneMonth))

        #expect(result.files == [talk, photo])
        #expect(result.counts.count(of: .lessThanOneMonth) == result.files.count)
    }

    @Test func aSearchLeavesFilesOutOfTheListAndOfEveryCount() {
        let result = filtered(LargeFileFilter(searchText: "p"))

        #expect(result.files == [trip, photo])
        #expect(result.counts.kinds == [.video: 1, .image: 1])
        #expect(result.counts.ages == [.overOneYear: 1, .lessThanOneMonth: 1])
        #expect(result.counts.sizes == [.over1GB: 1, .upTo100MB: 1])
    }

    @Test func filesWithNoKnownDateCountInNoAge() {
        let counts = filtered(LargeFileFilter(kinds: [.diskImage])).counts

        #expect(counts.ages.isEmpty)
        #expect(counts.count(of: .diskImage) == 1)
        #expect(counts.count(of: .from100MBTo1GB) == 1)
    }
}
