import Foundation

/// Reads the keys CleanMac needs from a launchd property list, in XML or binary form.
public enum LaunchPlistParser {
    /// The job the property list declares, or `nil` when it isn't a dictionary with a `Label`.
    public static func job(from data: Data) -> LaunchJobDefinition? {
        guard
            let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
            let label = nonEmptyString(plist["Label"])
        else { return nil }

        return LaunchJobDefinition(
            label: label,
            programPath: programPath(in: plist),
            runsAtLoad: plist["RunAtLoad"] as? Bool ?? false,
            keepsAlive: keepsAlive(plist["KeepAlive"]),
            isDisabled: plist["Disabled"] as? Bool ?? false
        )
    }

    private static func programPath(in plist: [String: Any]) -> String? {
        nonEmptyString(plist["Program"]) ?? nonEmptyString((plist["ProgramArguments"] as? [Any])?.first)
    }

    /// `KeepAlive` is either a Boolean or a dictionary of conditions, which keeps the job alive when they're met.
    private static func keepsAlive(_ value: Any?) -> Bool {
        switch value {
        case let flag as Bool: flag
        case let conditions as [String: Any]: !conditions.isEmpty
        default: false
        }
    }

    private static func nonEmptyString(_ value: Any?) -> String? {
        guard let string = value as? String, !string.isEmpty else { return nil }
        return string
    }
}
