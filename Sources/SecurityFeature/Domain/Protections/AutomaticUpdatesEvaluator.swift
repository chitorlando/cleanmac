import Foundation

/// Tells how well Software Update keeps security fixes coming from its preferences.
public enum AutomaticUpdatesEvaluator {
    /// Strings that some tools write instead of a Boolean.
    private static let trueStrings: Set<String> = ["1", "yes", "true"]

    /// - Parameter preferences: The contents of `com.apple.SoftwareUpdate.plist`, empty when
    ///   the file is missing. A missing key has the value macOS gives it, which is on for each
    ///   option, so a Mac whose settings were never touched updates itself.
    /// - Returns: On when every option is on, off when updates aren't even checked for,
    ///   and partial otherwise, with the options that are off.
    public static func check(preferences: [String: Any]) -> ProtectionCheck {
        let off = AutomaticUpdateOption.allCases.filter { !isOn($0, in: preferences) }
        guard !off.isEmpty else {
            return ProtectionCheck(kind: .automaticUpdates, state: .on)
        }
        let state: ProtectionState = off.contains(.checkForUpdates) ? .off : .partial
        return ProtectionCheck(kind: .automaticUpdates, state: state, detail: .updateOptionsOff(off))
    }

    private static func isOn(_ option: AutomaticUpdateOption, in preferences: [String: Any]) -> Bool {
        switch preferences[option.rawValue] {
        case let flag as Bool: flag
        case let number as Int: number != 0
        case let text as String: trueStrings.contains(text.lowercased())
        default: true
        }
    }
}
