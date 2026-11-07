import CleanMacCore
import Foundation

/// Measures an app bundle and its leftovers on disk.
struct InstalledAppMeasurer: Sendable {
    let sizer: any SizeCalculating

    func measure(_ info: AppBundleInfo, leftovers candidates: [LeftoverCandidate]) -> InstalledApp {
        let leftovers = candidates
            .map { Leftover(item: item(at: $0.url), kind: $0.location.kind) }
            .sorted { $0.item.size > $1.item.size }
        return InstalledApp(info: info, bundle: item(at: info.url), leftovers: leftovers)
    }

    private func item(at url: URL) -> CleanableItem {
        CleanableItem(url: url, size: sizer.size(of: url))
    }
}
