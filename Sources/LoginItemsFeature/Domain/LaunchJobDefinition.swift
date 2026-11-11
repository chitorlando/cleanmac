import Foundation

/// What a launchd property list declares about the job it starts.
public struct LaunchJobDefinition: Hashable, Sendable {
    public let label: String
    /// The executable, from `Program` or else the first of `ProgramArguments`. `nil` when absent.
    public let programPath: String?
    /// `RunAtLoad`: starts as soon as it's loaded, at login for agents or startup for daemons.
    public let runsAtLoad: Bool
    /// `KeepAlive`, either always or under some condition: launchd restarts it when it stops.
    public let keepsAlive: Bool
    /// `Disabled`: launchd ignores the job unless it was enabled by other means.
    public let isDisabled: Bool

    public init(label: String, programPath: String?, runsAtLoad: Bool, keepsAlive: Bool, isDisabled: Bool) {
        self.label = label
        self.programPath = programPath
        self.runsAtLoad = runsAtLoad
        self.keepsAlive = keepsAlive
        self.isDisabled = isDisabled
    }

    /// The program as a file URL, only when its path is absolute and can be checked on disk.
    public var programURL: URL? {
        guard let programPath, programPath.hasPrefix("/") else { return nil }
        return URL(filePath: programPath)
    }
}
