import CleanMacCore
import Foundation

/// Tells which listed apps are open, from the running apps the system reports.
///
/// An app is open when one runs from its bundle. It is also taken as open when a running app
/// that runs from no listed bundle has its bundle identifier: Gatekeeper runs a quarantined
/// app, such as one just downloaded, from a random read-only path (app translocation), so
/// its URL doesn't say where the app is. Every listed copy with that identifier counts then,
/// since nothing tells which one it is, and removing an open app's files could lose data.
struct RunningAppMatcher {
    private let runningURLs: Set<URL>
    /// URLs of the running apps that run from no listed bundle, by lowercased bundle identifier.
    private let instancesElsewhere: [String: [URL]]

    init(runningApps: [RunningApp], listedApps: [InstalledApp]) {
        let listedURLs = Set(listedApps.map(\.id.standardizedFileURL))
        var instancesElsewhere: [String: [URL]] = [:]
        for app in runningApps where !listedURLs.contains(app.url) {
            guard let bundleID = app.bundleID else { continue }
            instancesElsewhere[bundleID.lowercased(), default: []].append(app.url)
        }
        runningURLs = Set(runningApps.map(\.url))
        self.instancesElsewhere = instancesElsewhere
    }

    func isRunning(_ app: InstalledApp) -> Bool {
        runningURLs.contains(app.id.standardizedFileURL) || !instancesElsewhere(of: app).isEmpty
    }

    /// URLs of the running apps taken as `app` though they run from another place.
    func instancesElsewhere(of app: InstalledApp) -> [URL] {
        instancesElsewhere[app.info.bundleID.lowercased()] ?? []
    }
}
