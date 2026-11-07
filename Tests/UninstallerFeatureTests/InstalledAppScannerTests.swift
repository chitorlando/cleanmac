import CleanMacCore
import Foundation
import Testing
import UninstallerFeature

struct InstalledAppScannerTests {
    private let caches = LeftoverLocation(
        url: URL(filePath: "/home/Library/Caches"),
        kind: .caches,
        rules: [.bundleID, .bundleIDPrefix, .appName]
    )
    private let alpha = AppBundleInfo(url: URL(filePath: "/Applications/Alpha.app"), bundleID: "com.example.alpha", name: "Alpha")
    private let beta = AppBundleInfo(url: URL(filePath: "/Applications/Beta.app"), bundleID: "com.example.beta", name: "Beta")
    private let cleanMac = AppBundleInfo(url: URL(filePath: "/Applications/CleanMac.app"), bundleID: "io.github.cleanmac", name: "CleanMac")
    private let unreadable = URL(filePath: "/Applications/Broken.app")

    private func cache(_ name: String) -> URL { caches.url.appending(path: name) }

    private func makeScanner() -> InstalledAppScanner {
        let apps = [alpha, beta, cleanMac]
        let cacheItems = [cache("com.example.alpha"), cache("Alpha"), cache("com.example.beta.helper"), cache("CleanMac"), cache("Unrelated")]
        return InstalledAppScanner(
            applicationFolders: [URL(filePath: "/Applications")],
            locator: FakeAppLocator(apps: apps.map(\.url) + [unreadable]),
            infoReader: FakeAppInfoReader(infos: Dictionary(uniqueKeysWithValues: apps.map { ($0.url, $0) })),
            leftoverLocations: [caches],
            reader: FakeDirectoryReader(tree: [caches.url: cacheItems]),
            sizer: FakeSizeCalculator(sizes: [
                alpha.url: 1_000,
                beta.url: 2_000,
                cache("com.example.alpha"): 10,
                cache("Alpha"): 30,
                cache("com.example.beta.helper"): 50
            ]),
            excludedBundleIDs: ["io.github.cleanmac"]
        )
    }

    private func collectEvents() async -> [AppScanEvent] {
        var events: [AppScanEvent] = []
        for await event in makeScanner().scan() {
            events.append(event)
        }
        return events
    }

    private func analyzedApps(in events: [AppScanEvent]) -> [AppBundleInfo.ID: InstalledApp] {
        var apps: [AppBundleInfo.ID: InstalledApp] = [:]
        for case let .analyzed(app) in events {
            apps[app.id] = app
        }
        return apps
    }

    @Test func reportsDiscoveryFirstAndThenEachApp() async {
        let events = await collectEvents()

        #expect(events.count == 3)
        #expect(events.first == .discovered(count: 2))
    }

    @Test func skipsExcludedAndUnreadableApps() async {
        let apps = analyzedApps(in: await collectEvents())

        #expect(Set(apps.keys) == [alpha.id, beta.id])
    }

    @Test func attachesLeftoversSortedBySize() async throws {
        let apps = analyzedApps(in: await collectEvents())
        let scannedAlpha = try #require(apps[alpha.id])
        let scannedBeta = try #require(apps[beta.id])

        #expect(scannedAlpha.leftovers.map(\.item.name) == ["Alpha", "com.example.alpha"])
        #expect(scannedAlpha.leftovers.allSatisfy { $0.kind == .caches })
        #expect(scannedAlpha.totalSize == 1_040)
        #expect(scannedBeta.allItems.map(\.name) == ["Beta.app", "com.example.beta.helper"])
        #expect(scannedBeta.totalSize == 2_050)
    }
}
