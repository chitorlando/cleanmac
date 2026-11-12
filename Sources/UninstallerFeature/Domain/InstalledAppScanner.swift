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

    public func scan(including otherApps: [URL]) -> AsyncStream<AppScanEvent> {
        let scanner = self
        return AsyncStream { continuation in
            let task = Task {
                await scanner.run(including: otherApps, reportingTo: continuation)
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    public func canAnalyze(appAt url: URL) -> Bool {
        locator.application(at: url).flatMap(analyzableInfo(forAppAt:)) != nil
    }

    private func run(
        including otherApps: [URL],
        reportingTo continuation: AsyncStream<AppScanEvent>.Continuation
    ) async {
        let apps = discoverApps(including: otherApps)
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

    /// Apps of the application folders followed by the ones of `otherApps` that exist, once each.
    private func discoverApps(including otherApps: [URL]) -> [AppBundleInfo] {
        var seenPaths: Set<String> = []
        let apps = locator.applications(in: applicationFolders) + otherApps.compactMap(locator.application(at:))
        return apps
            .filter { seenPaths.insert($0.standardizedFileURL.path).inserted }
            .compactMap(analyzableInfo(forAppAt:))
    }

    /// The identity of the app at `url`, unless it can't be read or the app is one to leave out.
    private func analyzableInfo(forAppAt url: URL) -> AppBundleInfo? {
        guard let info = infoReader.info(forAppAt: url),
              !excludedBundleIDs.contains(info.bundleID.lowercased())
        else { return nil }
        return info
    }
}
