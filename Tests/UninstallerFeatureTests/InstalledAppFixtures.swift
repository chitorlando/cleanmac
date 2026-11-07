import CleanMacCore
import Foundation
import UninstallerFeature

/// Builds in-memory apps for presentation tests.
enum InstalledAppFixtures {
    static let library = URL(filePath: "/home/Library/Caches")

    static func app(
        _ name: String,
        bundleID: String? = nil,
        folder: String = "/Applications",
        size: Int64 = 100,
        leftovers: [String: Int64] = [:]
    ) -> InstalledApp {
        let url = URL(filePath: folder).appending(path: "\(name).app")
        let info = AppBundleInfo(url: url, bundleID: bundleID ?? "com.example.\(name.lowercased())", name: name)
        let items = leftovers
            .sorted { $0.key < $1.key }
            .map { Leftover(item: CleanableItem(url: library.appending(path: $0.key), size: $0.value), kind: .caches) }
        return InstalledApp(info: info, bundle: CleanableItem(url: url, size: size), leftovers: items)
    }
}
