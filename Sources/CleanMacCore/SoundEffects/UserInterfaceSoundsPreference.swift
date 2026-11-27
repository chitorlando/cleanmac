import CoreFoundation
import Foundation

/// `UserInterfaceSoundsReading` in the global preferences, where macOS keeps the choice the
/// user made in the Sound settings for every app.
///
/// It's read each time it's asked, since the user may change it while the app runs. macOS keeps
/// nothing until the user turns the sound effects off, so nothing kept means they play.
public struct UserInterfaceSoundsPreference: UserInterfaceSoundsReading {
    /// Name the choice is kept under, in the preferences of every app.
    static let key = "com.apple.sound.uiaudio.enabled"

    public init() {}

    public var playsUserInterfaceSounds: Bool {
        Self.playsSounds(kept: CFPreferencesCopyAppValue(Self.key as CFString, kCFPreferencesAnyApplication))
    }

    /// Whether `value`, what was kept under `key`, means that the sound effects play: anything
    /// but a number or a Boolean that is off, such as the 0 macOS keeps when they're turned off.
    static func playsSounds(kept value: Any?) -> Bool {
        guard let number = value as? NSNumber else { return true }
        return number.boolValue
    }
}
