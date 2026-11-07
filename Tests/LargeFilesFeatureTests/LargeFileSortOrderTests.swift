import Foundation
import LargeFilesFeature
import Testing

struct LargeFileSortOrderTests {
    private typealias Fixtures = LargeFileFixtures

    private let small = Fixtures.file("b-small.zip", megabytes: 60, lastUsed: Fixtures.date(2026, 1, 1))
    private let large = Fixtures.file("c-large.mov", megabytes: 900, lastUsed: Fixtures.date(2025, 1, 1))
    private let medium = Fixtures.file("a-medium.mp3", megabytes: 200, lastUsed: nil)
    private let musicMedium = Fixtures.file("a-medium.mp3", folder: "/Users/test/Music", megabytes: 200, lastUsed: nil)

    private var files: [LargeFile] { [small, large, medium, musicMedium] }

    @Test func sortsBySizeLargestFirst() {
        #expect(LargeFileSortOrder.size.sorted(files) == [large, musicMedium, medium, small])
    }

    @Test func sortsByNameThenPath() {
        #expect(LargeFileSortOrder.name.sorted(files) == [musicMedium, medium, small, large])
    }

    @Test func sortsByLeastRecentlyUsedWithUnknownDatesLast() {
        #expect(LargeFileSortOrder.lastAccess.sorted(files) == [large, small, musicMedium, medium])
    }

    @Test func sortsNamesWithNumbersAsTheFinderDoes() {
        let second = Fixtures.file("clip 2.mov", megabytes: 60)
        let tenth = Fixtures.file("clip 10.mov", megabytes: 60)
        #expect(LargeFileSortOrder.name.sorted([tenth, second]) == [second, tenth])
    }
}
