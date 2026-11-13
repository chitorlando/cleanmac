import Foundation
import OnboardingFeature
import Testing

struct UserDefaultsOnboardingStoreTests {
    @Test func remembersAcrossInstances() throws {
        let suite = "OnboardingFeatureTests-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }

        let store = UserDefaultsOnboardingStore(defaults: defaults)
        #expect(!store.isCompleted)
        #expect(!store.hadFullDiskAccess)

        store.isCompleted = true
        store.hadFullDiskAccess = true

        let again = UserDefaultsOnboardingStore(defaults: defaults)
        #expect(again.isCompleted)
        #expect(again.hadFullDiskAccess)
    }
}
