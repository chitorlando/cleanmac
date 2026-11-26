/// An option of Software Update's automatic updates that keeps security fixes coming,
/// named after its key in `/Library/Preferences/com.apple.SoftwareUpdate.plist`.
public enum AutomaticUpdateOption: String, CaseIterable, Hashable, Sendable {
    /// Check for updates.
    case checkForUpdates = "AutomaticCheckEnabled"
    /// Download new updates when available.
    case downloadUpdates = "AutomaticDownload"
    /// Install Security Responses and system files: the fixes that need no restart.
    case installSecurityResponses = "CriticalUpdateInstall"
    /// Install the data files of the system's protections, such as XProtect's definitions.
    case installSystemDataFiles = "ConfigDataInstall"
}
