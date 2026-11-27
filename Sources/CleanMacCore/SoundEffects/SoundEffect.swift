/// A moment of the app that a short sound marks, such as the end of a scan the user started.
///
/// It names the moment, not the sound: each one has its sound of macOS in `systemSound`.
public enum SoundEffect: CaseIterable, Hashable, Sendable {
    /// A scan or a review the user started ended, whatever it found.
    case scanFinished
    /// A cleanup moved items to the Trash.
    case cleanupFinished
    /// The uninstaller moved apps, or what they left behind, to the Trash.
    case appUninstalled
    /// The Trash was emptied.
    case trashEmptied
    /// Maintenance tasks ran, and at least one of them succeeded.
    case maintenanceFinished
    /// A malware review found a threat.
    case threatFound
}
