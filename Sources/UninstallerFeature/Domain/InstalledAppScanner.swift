import CleanMacCore
import Foundation

/// Finds installed apps and their leftovers, then measures every app in parallel,
/// reporting each one as soon as it is ready.
public struct InstalledAppScanner: InstalledAppScanning {
    private let applicationFolders: [URL]
    private let locator: any AppBundleLocating
    private let infoReader: any AppInfoReading
    private let leftoverLocations: [LeftoverLocation]
    private let reader: any DirectoryReading
    private let measurer: InstalledAppMeasurer
    private let excludedBundleIDs: Set<String>

    public init(
        applicationFolders: [URL],
        locator: any AppBundleLocating,
        infoReader: any AppInfoReading,
        leftoverLocations: [LeftoverLocation],
        reader: any DirectoryReading,
        sizer: any SizeCalculating,
        excludedBundleIDs: Set<String> = []
    ) {
        self.applicationFolders = applicationFolders
        self.locator = locator
        self.infoReader = infoReader
        self.leftoverLocations = leftoverLocations
        self.reader = reader
        self.measurer = InstalledAppMeasurer(sizer: sizer)
        self.excludedBundleIDs = Set(excludedBundleIDs.map { $0.lowercased() })
    }

    public func scan() -> AsyncStream<AppScanEvent> {
        let scanner = self
        return AsyncStream { continuation in
            let task = Task {
                await scanner.run(reportingTo: continuation)
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    private func run(reportingTo continuation: AsyncStream<AppScanEvent>.Continuation) async {
        let apps = discoverApps()
        continuation.yield(.discovered(count: apps.count))
        guard !Task.isCancelled else { return }

        let snapshot = LibrarySnapshot(locations: leftoverLocations, reader: reader)
        let leftovers = LeftoverAttributor().attribute(snapshot.candidates, to: apps)
        let measurer = measurer

        await withTaskGroup(of: InstalledApp.self) { group in
            for app in apps where !Task.isCancelled {
                let candidates = leftovers[app.id] ?? []
                group.addTask {
                    measurer.measure(app, leftovers: candidates)
                }
            }
            for await app in group {
                continuation.yield(.analyzed(app))
            }
        }
    }

    private func discoverApps() -> [AppBundleInfo] {
        locator.applications(in: applicationFolders)
            .compactMap(infoReader.info(forAppAt:))
            .filter { !excludedBundleIDs.contains($0.bundleID.lowercased()) }
    }
}
