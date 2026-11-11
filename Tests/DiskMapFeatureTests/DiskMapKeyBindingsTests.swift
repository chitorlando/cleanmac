@testable import DiskMapFeature
import Testing

struct DiskMapKeyBindingsTests {
    private let bindings = DiskMapKeyBindings()

    @Test func movesThroughTheItemsWithTheVerticalArrows() {
        #expect(bindings.action(for: .downArrow) == .moveHighlight(by: 1))
        #expect(bindings.action(for: .upArrow) == .moveHighlight(by: -1))
    }

    @Test func opensTheHighlightedFolderWithTheRightArrowOrReturn() {
        #expect(bindings.action(for: .rightArrow) == .openHighlighted)
        #expect(bindings.action(for: .return) == .openHighlighted)
    }

    @Test func goesUpWithTheLeftArrow() {
        #expect(bindings.action(for: .leftArrow) == .goUp)
    }
}
