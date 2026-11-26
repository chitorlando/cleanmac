/// A protection built into macOS that the security review looks at.
public enum ProtectionKind: CaseIterable, Hashable, Sendable {
    /// Encryption of the startup disk.
    case fileVault
    /// The application firewall, which filters incoming connections.
    case firewall
    /// The check that only lets apps from identified developers open.
    case gatekeeper
    /// System Integrity Protection, which keeps the system files from being changed.
    case systemIntegrityProtection
    /// Software Update installing security fixes on its own.
    case automaticUpdates
    /// XProtect, the malware definitions that macOS keeps up to date.
    case xprotect
}
