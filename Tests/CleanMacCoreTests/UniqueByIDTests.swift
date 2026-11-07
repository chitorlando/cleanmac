@testable import CleanMacCore
import Foundation
import Testing

struct UniqueByIDTests {
    private let first = CleanableItem(url: URL(filePath: "/tmp/a"), size: 1)
    private let second = CleanableItem(url: URL(filePath: "/tmp/b"), size: 2)

    @Test func dropsRepeatedIDsKeepingOrder() {
        let items = [first, second, first, second]

        #expect(items.uniquedByID() == [first, second])
    }

    @Test func keepsFirstOccurrenceWhenOnlyTheIDMatches() {
        let copy = CleanableItem(url: first.url, size: 99)

        #expect([first, copy].uniquedByID() == [first])
    }

    @Test func leavesEmptySequencesEmpty() {
        #expect([CleanableItem]().uniquedByID().isEmpty)
    }
}
