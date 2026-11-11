import Combine
import DiskMapFeature
import Foundation
import Testing

@MainActor
struct DiskMapHighlightTests {
    private func url(_ path: String) -> URL { DiskMapFixtures.home.appending(path: path) }

    @Test func startsOnNoItem() {
        let highlight = DiskMapHighlight()

        #expect(highlight.itemID == nil)
    }

    @Test func remembersTheItemItMovesTo() {
        let highlight = DiskMapHighlight()

        highlight.itemID = url("Movies")

        #expect(highlight.itemID == url("Movies"))
    }

    @Test func announcesItselfOnlyWhenItMoves() {
        let highlight = DiskMapHighlight()
        var announcements = 0
        let observation = highlight.objectWillChange.sink { announcements += 1 }

        highlight.itemID = url("Movies")
        highlight.itemID = url("Movies")
        #expect(announcements == 1)

        highlight.itemID = url("notes.txt")
        highlight.itemID = nil
        highlight.itemID = nil
        #expect(announcements == 3)
        #expect(highlight.itemID == nil)
        observation.cancel()
    }
}
