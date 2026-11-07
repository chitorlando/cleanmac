import SwiftUI

/// Circular progress indicator drawn with the feature's gradient.
public struct ProgressRing: View {
    private let progress: Double
    private let theme: FeatureTheme
    private let lineWidth: CGFloat

    public init(progress: Double, theme: FeatureTheme, lineWidth: CGFloat = 14) {
        self.progress = progress
        self.theme = theme
        self.lineWidth = lineWidth
    }

    public var body: some View {
        ZStack {
            Circle()
                .stroke(.white.opacity(0.08), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: max(0.02, min(progress, 1)))
                .stroke(theme.gradient, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .shadow(color: theme.primary.opacity(0.5), radius: 12)
                .animation(.smooth, value: progress)
        }
    }
}
