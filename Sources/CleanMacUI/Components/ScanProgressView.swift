import SwiftUI

/// Progress ring with a live value in the center, a status line and an optional stop button.
///
/// When the total amount of work is unknown, the ring spins instead of filling up. Behind it,
/// the glow of a scan breathes in the feature's colors.
public struct ScanProgressView: View {
    private static let ringDiameter: CGFloat = 220
    /// How far beyond the ring the particles of its glow set off from.
    private static let orbReach: CGFloat = 96

    private let progress: Double?
    private let value: String
    private let caption: Text
    private let status: Text
    private let theme: FeatureTheme
    private let onCancel: (() -> Void)?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// - Parameters:
    ///   - progress: Fraction of the work done, from 0 to 1, or `nil` when the total is unknown.
    ///   - value: Live figure shown inside the ring, such as the size found so far.
    ///   - caption: Short text below the value, such as “found”.
    ///   - status: What is happening, such as “Analyzing your Mac…”.
    ///   - onCancel: Shows a stop button when present.
    public init(
        progress: Double?,
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
                ring
                VStack(spacing: 4) {
                    Text(verbatim: value)
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .contentTransition(reduceMotion ? .opacity : .numericText())
                    caption
                        .foregroundStyle(.secondary)
                }
                .accessibilityElement(children: .combine)
            }
            .scanningOrb(theme: theme, reach: Self.orbReach)
            .frame(width: Self.ringDiameter, height: Self.ringDiameter)

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

    @ViewBuilder
    private var ring: some View {
        if let progress {
            ProgressRing(progress: progress, theme: theme)
        } else {
            IndeterminateProgressRing(theme: theme)
        }
    }
}
