@testable import CleanMacApp
import CleanMacCore
import Testing

@MainActor
struct AppLanguageTests {
    private func makePreferences(keeping languages: Any?) -> (Preferences, InMemoryPreferenceStorage) {
        let storage = InMemoryPreferenceStorage(languages.map { ["AppleLanguages": $0] } ?? [:])
        return (Preferences(storage: storage), storage)
    }

    @Test func followsTheSystemUntilTheUserChooses() {
        let (preferences, _) = makePreferences(keeping: nil)

        #expect(preferences.value(of: AppSettings.language) == .system)
    }

    @Test func keepsTheChoiceWhereMacOSReadsTheLanguagesOfTheApp() {
        let (preferences, storage) = makePreferences(keeping: nil)

        preferences.set(.spanish, for: AppSettings.language)
        #expect(storage.value(forKey: "AppleLanguages") as? [String] == ["es"])
        #expect(preferences.value(of: AppSettings.language) == .spanish)

        preferences.set(.english, for: AppSettings.language)
        #expect(storage.value(forKey: "AppleLanguages") as? [String] == ["en"])
    }

    @Test func choosingTheSystemRemovesTheOverride() {
        let (preferences, storage) = makePreferences(keeping: ["es"])

        preferences.set(.system, for: AppSettings.language)

        #expect(storage.value(forKey: "AppleLanguages") == nil)
        #expect(preferences.value(of: AppSettings.language) == .system)
    }

    @Test func readsALanguageWhateverItsRegion() {
        #expect(makePreferences(keeping: ["es-419", "en"]).0.value(of: AppSettings.language) == .spanish)
        #expect(makePreferences(keeping: ["en-GB"]).0.value(of: AppSettings.language) == .english)
    }

    @Test func fallsBackToTheSystemForWhatItCannotUse() {
        #expect(makePreferences(keeping: ["fr"]).0.value(of: AppSettings.language) == .system)
        #expect(makePreferences(keeping: [String]()).0.value(of: AppSettings.language) == .system)
        #expect(makePreferences(keeping: "es").0.value(of: AppSettings.language) == .system)
    }

    @Test func offersTheSystemAndEveryLanguageOfTheApp() {
        #expect(AppSettings.language.allowedValues == [.system, .english, .spanish])
    }
}
