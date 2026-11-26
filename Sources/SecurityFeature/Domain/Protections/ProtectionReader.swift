import CleanMacCore
import Foundation

/// Reads how each protection is set with the tools and files macOS reports it with.
///
/// Every tool is asked for its status only, which needs no administrator, and nothing is
/// changed. A tool that fails or prints something unexpected leaves its protection unknown.
public struct ProtectionReader: ProtectionReading {
    static let softwareUpdatePreferences = URL(filePath: "/Library/Preferences/com.apple.SoftwareUpdate.plist")

    /// Where macOS keeps XProtect's definitions: the first on every version, the second, which
    /// macOS 15 and later update, besides it. The newest copy is the one in use.
    static let xprotectInfoFiles = [
        URL(filePath: "/Library/Apple/System/Library/CoreServices/XProtect.bundle/Contents/Info.plist"),
        URL(filePath: "/private/var/protected/xprotect/XProtect.bundle/Contents/Info.plist")
    ]

    private let runner: any CommandRunning
    private let files: any ProtectionFileReading
    private let now: @Sendable () -> Date

    public init(
        runner: any CommandRunning = CommandRunner(),
        files: any ProtectionFileReading = FileSystemProtectionFiles(),
        now: @escaping @Sendable () -> Date = { Date() }
    ) {
        self.runner = runner
        self.files = files
        self.now = now
    }

    public func protections() async -> [ProtectionCheck] {
        async let fileVault = toolState(of: .fileVault)
        async let firewall = toolState(of: .firewall)
        async let gatekeeper = toolState(of: .gatekeeper)
        async let integrity = toolState(of: .systemIntegrityProtection)
        let updates = AutomaticUpdatesEvaluator.check(
            preferences: files.propertyList(at: Self.softwareUpdatePreferences) ?? [:]
        )
        let xprotect = XProtectEvaluator.check(bundles: xprotectBundles(), now: now())
        return [
            ProtectionCheck(kind: .fileVault, state: await fileVault),
            ProtectionCheck(kind: .firewall, state: await firewall),
            ProtectionCheck(kind: .gatekeeper, state: await gatekeeper),
            ProtectionCheck(kind: .systemIntegrityProtection, state: await integrity),
            updates,
            xprotect
        ]
    }

    /// The state the protection's tool reports. Some tools tell a protection that is off by
    /// exiting with an error, so what they printed is read either way.
    private func toolState(of kind: ProtectionTool) async -> ProtectionState {
        do {
            return kind.parse(try await runner.run(kind.executable, arguments: kind.arguments))
        } catch let failure as CommandFailure {
            return kind.parse(failure.output)
        } catch {
            return .unknown
        }
    }

    private func xprotectBundles() -> [XProtectBundle] {
        Self.xprotectInfoFiles.compactMap { url in
            guard let info = files.propertyList(at: url), let updatedAt = files.modificationDate(of: url) else {
                return nil
            }
            return XProtectBundle(version: info["CFBundleShortVersionString"] as? String, updatedAt: updatedAt)
        }
    }
}

/// A protection whose state a command-line tool of macOS reports.
enum ProtectionTool: Sendable {
    case fileVault
    case firewall
    case gatekeeper
    case systemIntegrityProtection

    var executable: URL {
        switch self {
        case .fileVault: URL(filePath: "/usr/bin/fdesetup")
        case .firewall: URL(filePath: "/usr/libexec/ApplicationFirewall/socketfilterfw")
        case .gatekeeper: URL(filePath: "/usr/sbin/spctl")
        case .systemIntegrityProtection: URL(filePath: "/usr/bin/csrutil")
        }
    }

    var arguments: [String] {
        switch self {
        case .fileVault, .systemIntegrityProtection: ["status"]
        case .firewall: ["--getglobalstate"]
        case .gatekeeper: ["--status"]
        }
    }

    func parse(_ output: String) -> ProtectionState {
        switch self {
        case .fileVault: ProtectionStatusParser.fileVault(output)
        case .firewall: ProtectionStatusParser.firewall(output)
        case .gatekeeper: ProtectionStatusParser.gatekeeper(output)
        case .systemIntegrityProtection: ProtectionStatusParser.systemIntegrityProtection(output)
        }
    }
}
