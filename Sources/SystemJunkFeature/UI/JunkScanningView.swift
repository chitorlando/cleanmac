import CleanMacUI
import SwiftUI

/// Progress while the scanners run.
struct JunkScanningView: View {
    let theme: FeatureTheme
    let progress: Double
    let foundSize: Int64
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 36) {
            ZStack {
                ProgressRing(progress: progress, theme: theme)
                VStack(spacing: 4) {
                    Text(foundSize.formattedByteCount)
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .contentTransition(.numericText())
                    Text("encontrados")
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 220, height: 220)

            Text("Analizando tu Mac…")
                .font(.title3.weight(.medium))

            Button("Detener", action: onCancel)
                .buttonStyle(.borderless)
                .foregroundStyle(.secondary)
                .keyboardShortcut(.cancelAction)
        }
        .animation(.smooth, value: foundSize)
    }
}
