import CleanMacUI
import SwiftUI

/// The installed memory as a bar, with the parts in use split as Activity Monitor does: app
/// memory, wired and compressed.
struct MemoryUsageBar: View {
    let usage: MemoryUsage
    let theme: FeatureTheme

    var body: some View {
        UsageBar(parts: [
            .init(id: 0, fraction: share(usage.app), color: theme.primary),
            .init(id: 1, fraction: share(usage.wired), color: theme.secondary),
            .init(id: 2, fraction: share(usage.compressed), color: .purple)
        ])
    }

    private func share(_ part: UInt64) -> Double {
        usage.physical > 0 ? Double(part) / Double(usage.physical) : 0
    }
}
