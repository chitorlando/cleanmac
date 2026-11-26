import Foundation

/// Reads the state of a protection from what the macOS tool that reports it prints.
///
/// Anything the parser doesn't recognize, such as the output of a future macOS that words it
/// differently or an error, is `unknown` rather than a guess.
public enum ProtectionStatusParser {
    /// `fdesetup status`, such as “FileVault is On.” A disk being decrypted counts as off and
    /// one being encrypted as on, since that's where it is heading.
    public static func fileVault(_ output: String) -> ProtectionState {
        let text = output.lowercased()
        if text.contains("decryption in progress") { return .off }
        if text.contains("filevault is on") || text.contains("encryption in progress") { return .on }
        if text.contains("filevault is off") { return .off }
        return .unknown
    }

    /// `socketfilterfw --getglobalstate`, such as “Firewall is enabled. (State = 1)”. State 2,
    /// which blocks every incoming connection, is on too.
    public static func firewall(_ output: String) -> ProtectionState {
        if let state = number(after: "State =", in: output) {
            return state == 0 ? .off : .on
        }
        let text = output.lowercased()
        if text.contains("firewall is enabled") { return .on }
        if text.contains("firewall is disabled") { return .off }
        return .unknown
    }

    /// `spctl --status`: “assessments enabled” or “assessments disabled”.
    public static func gatekeeper(_ output: String) -> ProtectionState {
        let text = output.lowercased()
        if text.contains("assessments enabled") { return .on }
        if text.contains("assessments disabled") { return .off }
        return .unknown
    }

    /// `csrutil status`, such as “System Integrity Protection status: enabled.” A custom
    /// configuration, where some of its parts were turned off, is partial whatever it says first.
    public static func systemIntegrityProtection(_ output: String) -> ProtectionState {
        guard let line = output
            .split(whereSeparator: \.isNewline)
            .first(where: { $0.lowercased().contains("integrity protection status:") })?
            .lowercased()
        else { return .unknown }
        if line.contains("custom configuration") { return .partial }
        if line.contains("status: enabled") { return .on }
        if line.contains("status: disabled") { return .off }
        return .unknown
    }

    /// The integer that follows `marker`, such as 1 in “(State = 1)”.
    private static func number(after marker: String, in output: String) -> Int? {
        guard let range = output.range(of: marker) else { return nil }
        let digits = output[range.upperBound...]
            .drop(while: { $0 == " " })
            .prefix(while: \.isNumber)
        return Int(digits)
    }
}
