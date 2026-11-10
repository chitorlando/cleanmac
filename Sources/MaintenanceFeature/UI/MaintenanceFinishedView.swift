import CleanMacUI
import SwiftUI

/// Outcome of every task that ran, and a button to start over.
struct MaintenanceFinishedView: View {
    let report: MaintenanceReport
    let theme: FeatureTheme
    let onDone: () -> Void

    private static let maxListHeight: CGFloat = 320
    /// Height the list keeps in a short window, where it scrolls instead of pushing the rest off screen.
    private static let minListHeight: CGFloat = 96
    @State private var listHeight: CGFloat = 0

    var body: some View {
        VStack(spacing: 32) {
            HeroHeader(symbolName: symbolName, title: title, subtitle: subtitle, theme: theme)
            GlassCard {
                // Hugs short reports, and scrolls once they outgrow the maximum height or the window.
                ScrollView {
                    results
                        .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { listHeight = $0 }
                }
                .scrollBounceBehavior(.basedOnSize)
                .frame(minHeight: min(listHeight, Self.minListHeight), maxHeight: min(listHeight, Self.maxListHeight))
            }
            DoneButton(theme: theme, action: onDone)
        }
        .frame(minWidth: 460, maxWidth: 620)
    }

    private var results: some View {
        VStack(spacing: 14) {
            ForEach(report.results, id: \.task) { result in
                MaintenanceResultRow(result: result)
            }
        }
    }

    private var isClean: Bool { report.failures.isEmpty }

    private var symbolName: String {
        isClean ? "checkmark.seal.fill" : "exclamationmark.triangle.fill"
    }

    private var title: String {
        isClean
            ? String(localized: "Maintenance complete", bundle: .module, comment: "Title after every maintenance task succeeded.")
            : String(localized: "Some tasks didn’t complete", bundle: .module, comment: "Title after one or more maintenance tasks failed.")
    }

    private var subtitle: String {
        isClean
            ? String(
                localized: "\(report.results.count) tasks finished successfully.",
                bundle: .module,
                comment: "Subtitle after every maintenance task succeeded. The argument is how many tasks ran."
            )
            : String(
                localized: "\(report.failures.count) tasks need your attention. See the details below.",
                bundle: .module,
                comment: "Subtitle after some maintenance tasks failed. The argument is how many failed."
            )
    }
}
