@testable import DiskMapFeature
import Testing

struct DiskMapKeyTests {
    @Test func recognizesTheArrowsAndReturnByTheirKeyCodes() {
        #expect(DiskMapKey(keyCode: 126) == .upArrow)
        #expect(DiskMapKey(keyCode: 125) == .downArrow)
        #expect(DiskMapKey(keyCode: 123) == .leftArrow)
        #expect(DiskMapKey(keyCode: 124) == .rightArrow)
        #expect(DiskMapKey(keyCode: 36) == .return)
    }

    @Test func ignoresEveryOtherKey() {
        // The keypad's Enter, Space, Escape, Tab and the letter A.
        let otherKeyCodes: [UInt16] = [76, 49, 53, 48, 0]

        for keyCode in otherKeyCodes {
            #expect(DiskMapKey(keyCode: keyCode) == nil)
        }
    }
}
