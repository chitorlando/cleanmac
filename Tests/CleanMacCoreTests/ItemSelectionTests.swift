import CleanMacCore
import Foundation
import Testing

struct ItemSelectionTests {
    private let first = CleanableItem(url: URL(filePath: "/tmp/a"), size: 10)
    private let second = CleanableItem(url: URL(filePath: "/tmp/b"), size: 20)

    @Test func startsEmpty() {
        let selection = ItemSelection()
        #expect(selection.isEmpty)
        #expect(selection.state(of: [first, second]) == .none)
    }

    @Test func reportsPartialSelection() {
        var selection = ItemSelection()
        selection.toggle(first)
        #expect(selection.state(of: [first, second]) == .some)
    }

    @Test func toggleAllSelectsThenClears() {
        var selection = ItemSelection()
        selection.toggleAll([first, second])
        #expect(selection.state(of: [first, second]) == .all)
        selection.toggleAll([first, second])
        #expect(selection.isEmpty)
    }

    @Test func toggleAllFromPartialSelectsEverything() {
        var selection = ItemSelection()
        selection.toggle(first)
        selection.toggleAll([first, second])
        #expect(selection.selectedItems(in: [first, second]) == [first, second])
    }
}
