import CleanMacCore

/// Reads which jobs launchd was told to enable or disable, as `launchctl enable` and
/// `launchctl disable` do, whatever the `Disabled` key of their property lists says.
public protocol LaunchOverridesReading: Sendable {
    /// The overrides of the launchd domain that loads items of `kind`, by job label: `true`
    /// for a disabled job, `false` for an enabled one. Empty when there are none or they
    /// can't be read.
    func overrides(for kind: LaunchItemKind) -> [String: Bool]
}
