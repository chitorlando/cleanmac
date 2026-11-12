import CleanMacCore
import Foundation

/// `AppLocating` that knows a fixed set of apps by bundle identifier.
struct FakeAppLocator: AppLocating {
    var apps: [String: URL] = [:]

    func appURL(forBundleID bundleID: String) -> URL? {
        apps[bundleID]
    }
}
