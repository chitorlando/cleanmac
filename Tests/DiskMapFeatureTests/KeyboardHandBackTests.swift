@testable import DiskMapFeature
import Testing

struct KeyboardHandBackTests {
    @Test func givesTheKeyboardBackOnAClickInsideTheContent() {
        let handBack = KeyboardHandBack(isInsideContent: true, isUnderSheet: false, isEditingText: false)

        #expect(handBack.givesKeyboardToContent)
    }

    @Test func ignoresClicksOutsideTheContent() {
        let handBack = KeyboardHandBack(isInsideContent: false, isUnderSheet: false, isEditingText: false)

        #expect(!handBack.givesKeyboardToContent)
    }

    @Test func leavesTheKeyboardAloneUnderASheet() {
        let handBack = KeyboardHandBack(isInsideContent: true, isUnderSheet: true, isEditingText: false)

        #expect(!handBack.givesKeyboardToContent)
    }

    @Test func neverTakesTheKeyboardFromSomeoneTyping() {
        let handBack = KeyboardHandBack(isInsideContent: true, isUnderSheet: false, isEditingText: true)

        #expect(!handBack.givesKeyboardToContent)
    }
}
