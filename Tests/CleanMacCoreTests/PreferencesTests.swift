import CleanMacCore
import Combine
import Testing

@MainActor
struct PreferencesTests {
    private let interval = Setting(key: "interval", defaultValue: 2, allowedValues: [1, 2, 5])
    private let limit = Setting(key: "limit", defaultValue: 50)

    @Test func aSettingTheUserNeverChangedHasItsDefault() {
        let preferences = Preferences(storage: InMemoryPreferenceStorage())

        #expect(preferences.value(of: interval) == 2)
        #expect(preferences.value(of: limit) == 50)
    }

    @Test func keepsWhatTheUserChose() {
        let storage = InMemoryPreferenceStorage()
        let preferences = Preferences(storage: storage)

        preferences.set(5, for: interval)

        #expect(preferences.value(of: interval) == 5)
        #expect(storage.value(forKey: "interval") as? Int == 5)
        #expect(Preferences(storage: storage).value(of: interval) == 5)
    }

    @Test func keepsEachSettingUnderItsOwnKey() {
        let preferences = Preferences(storage: InMemoryPreferenceStorage())

        preferences.set(5, for: interval)

        #expect(preferences.value(of: limit) == 50)
    }

    @Test func fallsBackToTheDefaultWhenWhatWasKeptIsNotAllowed() {
        let preferences = Preferences(storage: InMemoryPreferenceStorage(["interval": 3]))

        #expect(preferences.value(of: interval) == 2)
    }

    @Test func fallsBackToTheDefaultWhenWhatWasKeptIsOfAnotherKind() {
        let preferences = Preferences(storage: InMemoryPreferenceStorage(["interval": "fast", "limit": ["a", "b"]]))

        #expect(preferences.value(of: interval) == 2)
        #expect(preferences.value(of: limit) == 50)
    }

    @Test func takesAnyValueWhenTheSettingListsNone() {
        let preferences = Preferences(storage: InMemoryPreferenceStorage())

        preferences.set(1_234, for: limit)

        #expect(preferences.value(of: limit) == 1_234)
    }

    @Test func ignoresAValueTheSettingDoesNotTake() {
        let storage = InMemoryPreferenceStorage(["interval": 5])
        let preferences = Preferences(storage: storage)

        preferences.set(3, for: interval)

        #expect(preferences.value(of: interval) == 5)
        #expect(storage.value(forKey: "interval") as? Int == 5)
    }

    @Test func keepsTheDefaultByKeepingNothing() {
        let storage = InMemoryPreferenceStorage(["interval": 5])
        let preferences = Preferences(storage: storage)

        preferences.set(2, for: interval)

        #expect(preferences.value(of: interval) == 2)
        #expect(storage.value(forKey: "interval") == nil)
    }

    @Test func choosingTheDefaultForgetsAValueThatCouldNotBeUsed() {
        let storage = InMemoryPreferenceStorage(["interval": 3])
        let preferences = Preferences(storage: storage)

        preferences.set(2, for: interval)

        #expect(storage.value(forKey: "interval") == nil)
    }

    @Test func tellsEachNewValue() {
        let preferences = Preferences(storage: InMemoryPreferenceStorage())
        var values: [Int] = []
        let observation = preferences.changes(of: interval).sink { values.append($0) }

        preferences.set(5, for: interval)
        preferences.set(1, for: interval)
        preferences.set(2, for: interval)

        #expect(values == [5, 1, 2])
        observation.cancel()
    }

    @Test func tellsNothingWhileTheValueStaysTheSame() {
        let preferences = Preferences(storage: InMemoryPreferenceStorage(["interval": 3]))
        var values: [Int] = []
        let observation = preferences.changes(of: interval).sink { values.append($0) }

        preferences.set(2, for: interval)
        preferences.set(3, for: interval)
        preferences.set(5, for: interval)
        preferences.set(5, for: interval)

        #expect(values == [5])
        observation.cancel()
    }

    @Test func tellsOnlyAboutTheSettingFollowed() {
        let preferences = Preferences(storage: InMemoryPreferenceStorage())
        var values: [Int] = []
        let observation = preferences.changes(of: limit).sink { values.append($0) }

        preferences.set(5, for: interval)
        preferences.set(80, for: limit)

        #expect(values == [80])
        observation.cancel()
    }

    @Test func tellsNothingAfterTheObservationEnds() {
        let preferences = Preferences(storage: InMemoryPreferenceStorage())
        var values: [Int] = []
        let observation = preferences.changes(of: interval).sink { values.append($0) }

        observation.cancel()
        preferences.set(5, for: interval)

        #expect(values.isEmpty)
    }
}
