import AppKit

/// `RunningAppsProviding` backed by `NSWorkspace`. Apps are matched by standardized bundle URL.
@MainActor
public struct WorkspaceRunningApps: RunningAppsProviding {
    private let workspace: NSWorkspace
    private let timeout: Duration
    private let pollInterval: Duration

    public init(
        workspace: NSWorkspace = .shared,
        timeout: Duration = .seconds(10),
        pollInterval: Duration = .milliseconds(200)
    ) {
        self.workspace = workspace
        self.timeout = timeout
        self.pollInterval = pollInterval
    }

    public func runningAppURLs() -> Set<URL> {
        Set(workspace.runningApplications.compactMap { $0.bundleURL?.standardizedFileURL })
    }

    public func quit(appAt url: URL) async -> Bool {
        let target = url.standardizedFileURL
        let instances = workspace.runningApplications.filter { $0.bundleURL?.standardizedFileURL == target }
        instances.forEach { $0.terminate() }
        return await waitUntilTerminated(instances)
    }

    private func waitUntilTerminated(_ instances: [NSRunningApplication]) async -> Bool {
        let deadline = ContinuousClock.now + timeout
        while instances.contains(where: { !$0.isTerminated }) {
            guard ContinuousClock.now < deadline else { return false }
            do {
                try await Task.sleep(for: pollInterval)
            } catch {
                return false
            }
        }
        return true
    }
}
