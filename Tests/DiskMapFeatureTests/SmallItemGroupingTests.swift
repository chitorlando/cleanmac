import DiskMapFeature
import Testing

struct SmallItemGroupingTests {
    private let grouping = SmallItemGrouping(minimumShare: 0.01, minimumSize: 1_000)

    @Test func treatsItemsBelowTheShareOfTheirFolderAsSmall() {
        #expect(grouping.isSmall(99, inFolderOf: 10_000))
        #expect(!grouping.isSmall(100, inFolderOf: 10_000))
    }

    @Test func alwaysShowsItemsOfTheMinimumSize() {
        #expect(grouping.isSmall(999, inFolderOf: 10_000_000))
        #expect(!grouping.isSmall(1_000, inFolderOf: 10_000_000))
    }

    @Test func countsEmptyItemsAsSmall() {
        #expect(grouping.isSmall(0, inFolderOf: 0))
        #expect(grouping.isSmall(0, inFolderOf: 10_000))
    }

    @Test func groupsOnePercentAndTenMegabytesByDefault() {
        let grouping = SmallItemGrouping()

        #expect(grouping.minimumShare == 0.01)
        #expect(grouping.minimumSize == 10_000_000)
    }

    @Test func canShowEveryItem() {
        #expect(!SmallItemGrouping.off.isSmall(0, inFolderOf: 1_000_000))
        #expect(!SmallItemGrouping.off.isSmall(1, inFolderOf: 1_000_000))
    }

    @Test func keepsTheLimitsInRange() {
        let grouping = SmallItemGrouping(minimumShare: 3, minimumSize: -5)

        #expect(grouping.minimumShare == 1)
        #expect(grouping.minimumSize == 0)
        #expect(SmallItemGrouping(minimumShare: -1).minimumShare == 0)
    }
}
