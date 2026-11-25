import Foundation

/// What a launchd property list declares about the job it starts.
public struct LaunchJobDefinition: Hashable, Sendable {
    public let label: String
    /// The executable, from `Program` or else the first of `ProgramArguments`. `nil` when absent.
    public let programPath: String?
    /// What the program is started with: `ProgramArguments` without its first element, which
    /// names the program.
    public let arguments: [String]
    /// `RunAtLoad`: starts as soon as it's loaded, at login for agents or startup for daemons.
    public let runsAtLoad: Bool
    /// `KeepAlive`, either always or under some condition: launchd restarts it when it stops.
    public let keepsAlive: Bool
    /// `Disabled`: launchd ignores the job unless it was enabled by other means.
    public let isDisabled: Bool

    public init(
        label: String,
        programPath: String?,
        arguments: [String] = [],
        runsAtLoad: Bool,
        keepsAlive: Bool,
        isDisabled: Bool
    ) {
        self.label = label
        self.programPath = programPath
        self.arguments = arguments
        self.runsAtLoad = runsAtLoad
        self.keepsAlive = keepsAlive
        self.isDisabled = isDisabled
    }

    /// The program as a file URL, only when its path is absolute and can be checked on disk.
    public var programURL: URL? {
        guard let programPath, programPath.hasPrefix("/") else { return nil }
        return URL(filePath: programPath)
    }

    /// What the job can't run without and can be checked on disk: its program and, when that
    /// is a known interpreter or launcher, the script or app it is plainly asked to run.
    public var requiredItems: [URL] {
        guard let programPath else { return [] }
        let targets = LaunchTargets.paths(program: programPath, arguments: arguments)
        return [programURL].compactMap { $0 } + targets.map { URL(filePath: $0) }
    }
}
