import CleanMacCore
import CleanMacUI
import SwiftUI

/// Result of a cleanup.
struct JunkFinishedView: View {
    let report: CleanupReport
    let theme: FeatureTheme
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: 40) {
            HeroHeader(
                symbolName: "checkmark.seal.fill",
                title: "\(report.freedBytes.formattedByteCount) liberados",
                subtitle: summary,
                theme: theme
            )
            if !report.failures.isEmpty {
                JunkFailureList(failures: report.failures)
            }
            Button("Listo", action: onDone)
                .buttonStyle(GlowButtonStyle(theme: theme, shape: .capsule))
                .keyboardShortcut(.defaultAction)
        }
        .frame(maxWidth: 560)
    }

    private var summary: String {
        "\(report.removedCount) elementos movidos a la Papelera. Vacíala para recuperar el espacio en disco."
    }
}
