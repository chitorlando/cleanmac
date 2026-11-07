import SwiftUI

/// Progress ring with a live value in the center, a status line and an optional stop button.
public struct ScanProgressView: View {
    private let progress: Double
    private let value: String
    private let caption: Text
    private let status: Text
    private let theme: FeatureTheme
    private let onCancel: (() -> Void)?

    /// - Parameters:
    ///   - value: Live figure shown inside the ring, such as the size found so far.
    ///   - caption: Short text below the value, such as “found”.
    ///   - status: What is happening, such as “Analyzing your Mac…”.
    ///   - onCancel: Shows a stop button when present.
    public init(
        progress: Double,
        value: String,
        caption: Text,
        status: Text,
        theme: FeatureTheme,
        onCancel: (() -> Void)? = nil
    ) {
        self.progress = progress
        self.value = value
        self.caption = caption
        self.status = status
        self.theme = theme
        self.onCancel = onCancel
    }

    public var body: some View {
        VStack(spacing: 36) {
            ZStack {
                ProgressRing(progress: progress, theme: theme)
                VStack(spacing: 4) {
                    Text(verbatim: value)
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .contentTransition(.numericText())
                    caption
                        .foregroundStyle(.secondary)
                }
                .accessibilityElement(children: .combine)
            }
            .frame(width: 220, height: 220)

            status
                .font(.title3.weight(.medium))

            if let onCancel {
                Button(action: onCancel) {
                    Text("Stop", bundle: .module, comment: "Button that cancels a scan in progress.")
                }
                .buttonStyle(.borderless)
                .foregroundStyle(.secondary)
                .keyboardShortcut(.cancelAction)
            }
        }
        .animation(.smooth, value: value)
    }
}
