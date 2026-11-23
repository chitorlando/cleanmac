import Foundation

/// `PreferenceStorage` in the user defaults, where macOS keeps the preferences of each app.
///
/// Reads only what was kept for the app itself. `UserDefaults` would also answer with what
/// every app shares, such as the languages of the system under `AppleLanguages`, and that
/// isn't something the user chose here.
@MainActor
public struct UserDefaultsPreferenceStorage: PreferenceStorage {
    private let defaults: UserDefaults
    private let domainName: String

    /// - Parameters:
    ///   - defaults: Where the values are written.
    ///   - domainName: Name of the domain `defaults` writes to: the identifier of the app
    ///     for the standard defaults, or the name of the suite.
    public init(defaults: UserDefaults, domainName: String) {
        self.defaults = defaults
        self.domainName = domainName
    }

    public func value(forKey key: String) -> Any? {
        defaults.persistentDomain(forName: domainName)?[key]
    }

    public func set(_ value: Any, forKey key: String) {
        defaults.set(value, forKey: key)
    }

    public func removeValue(forKey key: String) {
        defaults.removeObject(forKey: key)
    }
}

public extension UserDefaultsPreferenceStorage {
    /// Storage in the defaults of the running app. A program with no bundle identifier
    /// has its defaults under its own name.
    static func standard() -> UserDefaultsPreferenceStorage {
        UserDefaultsPreferenceStorage(
            defaults: .standard,
            domainName: Bundle.main.bundleIdentifier ?? ProcessInfo.processInfo.processName
        )
    }
}
