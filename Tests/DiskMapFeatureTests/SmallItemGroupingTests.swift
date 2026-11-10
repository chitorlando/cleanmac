import DiskMapFeature
import Testing

struct SmallItemGroupingTests {
    @Test func treatsItemsBelowTheShareOfTheirFolderAsSmall() {
        let grouping = SmallItemGrouping(minimumShare: 0.01)

        #expect(grouping.isSmall(99, inFolderOf: 10_000))
        #expect(!grouping.isSmall(100, inFolderOf: 10_000))
    }

    @Test func groupsOnePercentByDefault() {
        #expect(SmallItemGrouping().minimumShare == 0.01)
    }

    @Test func findsNothingSmallInAnEmptyFolder() {
        #expect(!SmallItemGrouping().isSmall(0, inFolderOf: 0))
    }

    @Test func showsEveryItemWithAShareOfZero() {
        #expect(!SmallItemGrouping(minimumShare: 0).isSmall(0, inFolderOf: 1_000_000))
    }

    @Test func keepsTheShareBetweenNothingAndEverything() {
        #expect(SmallItemGrouping(minimumShare: -1).minimumShare == 0)
        #expect(SmallItemGrouping(minimumShare: 3).minimumShare == 1)
    }
}
