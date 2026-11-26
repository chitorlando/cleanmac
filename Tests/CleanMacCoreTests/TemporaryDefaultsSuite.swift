import CleanMacCore
import Foundation

/// User defaults under a unique name, removed when the test ends, with the storage that reads them.
@MainActor
final class TemporaryDefaultsSuite {
    private struct Unavailable: Error {}

    let name = "CleanMacCoreTests-\(UUID().uuidString)"
    let defaults: UserDefaults
    let storage: UserDefaultsPreferenceStorage

    init() throws {
        guard let defaults = UserDefaults(suiteName: name) else { throw Unavailable() }
        self.defaults = defaults
        storage = UserDefaultsPreferenceStorage(defaults: defaults, domainName: name)
    }

    deinit {
        UserDefaults.standard.removePersistentDomain(forName: name)
    }
}
