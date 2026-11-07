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
                    Text("found", bundle: .module, comment: "Caption below the amount of junk found so far, as in “1.2 GB found”.")
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 220, height: 220)

            Text("Analyzing your Mac…", bundle: .module, comment: "Status shown while scanning.")
                .font(.title3.weight(.medium))

            Button(action: onCancel) {
                Text("Stop", bundle: .module, comment: "Button that cancels the scan.")
            }
            .buttonStyle(.borderless)
            .foregroundStyle(.secondary)
            .keyboardShortcut(.cancelAction)
        }
        .animation(.smooth, value: foundSize)
    }
}
