import Foundation
import os
import UninstallerFeature

/// Analyzes the apps a scan is asked to include that are on disk when it starts, so a test
/// can take an app away and bring it back between two loads.
final class ChangingAppScanner: InstalledAppScanning {
    private let appsOnDisk: OSAllocatedUnfairLock<[InstalledApp]>

    init(appsOnDisk: [InstalledApp]) {
        self.appsOnDisk = OSAllocatedUnfairLock(initialState: appsOnDisk)
    }

    func remove(_ app: InstalledApp) {
        appsOnDisk.withLock { apps in
            apps.removeAll { $0.id == app.id }
        }
    }

    func add(_ app: InstalledApp) {
        appsOnDisk.withLock { apps in
            apps.append(app)
        }
    }

    func scan(including otherApps: [URL]) -> AsyncStream<AppScanEvent> {
        let requestedPaths = Set(otherApps.map(\.standardizedFileURL.path))
        let apps = appsOnDisk.withLock { $0 }
            .filter { requestedPaths.contains($0.id.standardizedFileURL.path) }
        return AsyncStream { continuation in
            continuation.yield(.discovered(count: apps.count))
            apps.forEach { continuation.yield(.analyzed($0)) }
            continuation.finish()
        }
    }

    func canAnalyze(appAt url: URL) -> Bool {
        let path = url.standardizedFileURL.path
        return appsOnDisk.withLock { $0 }.contains { $0.id.standardizedFileURL.path == path }
    }
}
