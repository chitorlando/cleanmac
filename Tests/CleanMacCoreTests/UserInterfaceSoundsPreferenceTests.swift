@testable import CleanMacCore
import Foundation
import Testing

struct UserInterfaceSoundsPreferenceTests {
    /// The key System Settings writes in the global preferences.
    @Test func readsTheChoiceOfTheSoundSettings() {
        #expect(UserInterfaceSoundsPreference.key == "com.apple.sound.uiaudio.enabled")
    }

    /// macOS keeps nothing until the user turns them off.
    @Test func soundEffectsPlayWhenNothingIsKept() {
        #expect(UserInterfaceSoundsPreference.playsSounds(kept: nil))
    }

    /// macOS keeps a 0 when the user turns them off, and a 1 when they're turned on again.
    @Test func followsTheNumberMacOSKeeps() {
        #expect(!UserInterfaceSoundsPreference.playsSounds(kept: NSNumber(value: 0)))
        #expect(UserInterfaceSoundsPreference.playsSounds(kept: NSNumber(value: 1)))
    }

    @Test func followsABoolean() {
        #expect(!UserInterfaceSoundsPreference.playsSounds(kept: false))
        #expect(UserInterfaceSoundsPreference.playsSounds(kept: true))
    }

    @Test func soundEffectsPlayWhenWhatIsKeptIsNotAChoice() {
        #expect(UserInterfaceSoundsPreference.playsSounds(kept: "off"))
    }
}
