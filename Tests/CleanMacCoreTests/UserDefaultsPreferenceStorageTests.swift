import CleanMacCore
import Foundation
import Testing

@MainActor
struct UserDefaultsPreferenceStorageTests {
    @Test func keepsNothingAtFirst() throws {
        let suite = try TemporaryDefaultsSuite()

        #expect(suite.storage.value(forKey: "interval") == nil)
    }

    @Test func keepsAValueInTheDefaults() throws {
        let suite = try TemporaryDefaultsSuite()

        suite.storage.set(5, forKey: "interval")

        #expect(suite.storage.value(forKey: "interval") as? Int == 5)
        #expect(suite.defaults.integer(forKey: "interval") == 5)
    }

    @Test func readsWhatTheDefaultsAlreadyHeld() throws {
        let suite = try TemporaryDefaultsSuite()

        suite.defaults.set(["es"], forKey: "languages")

        #expect(suite.storage.value(forKey: "languages") as? [String] == ["es"])
    }

    @Test func forgetsAValue() throws {
        let suite = try TemporaryDefaultsSuite()
        suite.storage.set(5, forKey: "interval")

        suite.storage.removeValue(forKey: "interval")

        #expect(suite.storage.value(forKey: "interval") == nil)
        #expect(suite.defaults.object(forKey: "interval") == nil)
    }

    /// The defaults also answer with values nobody kept for the app, such as the languages
    /// of the system under `AppleLanguages`. A registered value stands in for them here.
    @Test func leavesOutWhatWasNotKeptForTheApp() throws {
        let suite = try TemporaryDefaultsSuite()

        suite.defaults.register(defaults: ["AppleLanguages": ["fr"]])

        #expect(suite.defaults.object(forKey: "AppleLanguages") != nil)
        #expect(suite.storage.value(forKey: "AppleLanguages") == nil)
    }

    @Test func servesThePreferencesOfTheApp() throws {
        let suite = try TemporaryDefaultsSuite()
        let interval = Setting(key: "interval", defaultValue: 2, allowedValues: [1, 2, 5])
        let preferences = Preferences(storage: suite.storage)

        preferences.set(5, for: interval)
        #expect(Preferences(storage: suite.storage).value(of: interval) == 5)

        preferences.set(2, for: interval)
        #expect(suite.defaults.object(forKey: "interval") == nil)
    }

    /// The defaults give back a number of their own, which still reads as the size kept.
    @Test func servesSizesInBytes() throws {
        let suite = try TemporaryDefaultsSuite()
        let size = Setting<Int64>(key: "size", defaultValue: 50_000_000, allowedValues: [50_000_000, 5_000_000_000])

        Preferences(storage: suite.storage).set(5_000_000_000, for: size)

        #expect(Preferences(storage: suite.storage).value(of: size) == 5_000_000_000)
        #expect(suite.defaults.object(forKey: "size") as? Int64 == 5_000_000_000)
    }
}
