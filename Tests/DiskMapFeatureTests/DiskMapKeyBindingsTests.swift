@testable import DiskMapFeature
import Testing

struct DiskMapKeyBindingsTests {
    private let bindings = DiskMapKeyBindings()

    @Test func movesThroughTheItemsWithTheVerticalArrows() {
        #expect(bindings.action(for: .downArrow, hasSelection: false) == .moveHighlight(by: 1))
        #expect(bindings.action(for: .upArrow, hasSelection: false) == .moveHighlight(by: -1))
    }

    @Test func opensTheHighlightedFolderWithTheRightArrowOrReturn() {
        #expect(bindings.action(for: .rightArrow, hasSelection: false) == .openHighlighted)
        #expect(bindings.action(for: .return, hasSelection: false) == .openHighlighted)
    }

    @Test func goesUpWithTheLeftArrow() {
        #expect(bindings.action(for: .leftArrow, hasSelection: false) == .goUp)
    }

    @Test func leavesReturnToTheMainButtonWhileSomethingIsSelected() {
        #expect(bindings.action(for: .return, hasSelection: true) == nil)
    }

    @Test func keepsTheArrowsWhileSomethingIsSelected() {
        #expect(bindings.action(for: .downArrow, hasSelection: true) == .moveHighlight(by: 1))
        #expect(bindings.action(for: .upArrow, hasSelection: true) == .moveHighlight(by: -1))
        #expect(bindings.action(for: .rightArrow, hasSelection: true) == .openHighlighted)
        #expect(bindings.action(for: .leftArrow, hasSelection: true) == .goUp)
    }
}
