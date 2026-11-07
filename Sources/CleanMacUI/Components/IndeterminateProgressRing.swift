import SwiftUI

/// Ring with a glowing arc that spins while the total amount of work is unknown.
///
/// With Reduce Motion on, it shows a still ring instead.
public struct IndeterminateProgressRing: View {
    private static let period: TimeInterval = 1.4
    private static let arcLength = 0.3

    private let theme: FeatureTheme
    private let lineWidth: CGFloat
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(theme: FeatureTheme, lineWidth: CGFloat = 14) {
        self.theme = theme
        self.lineWidth = lineWidth
    }

    public var body: some View {
        ZStack {
            Circle()
                .stroke(.white.opacity(0.08), lineWidth: lineWidth)
            if reduceMotion {
                stillRing
            } else {
                TimelineView(.animation) { context in
                    arc.rotationEffect(angle(at: context.date))
                }
            }
        }
        .accessibilityHidden(true)
    }

    private var stillRing: some View {
        Circle()
            .stroke(theme.gradient, lineWidth: lineWidth)
            .shadow(color: theme.primary.opacity(0.5), radius: 12)
    }

    private var arc: some View {
        Circle()
            .trim(from: 0, to: Self.arcLength)
            .stroke(tail, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
            .shadow(color: theme.primary.opacity(0.5), radius: 12)
    }

    /// Fades from transparent at the end of the arc to the theme's colors at its head.
    private var tail: AngularGradient {
        AngularGradient(
            colors: [theme.secondary.opacity(0), theme.secondary, theme.primary],
            center: .center,
            startAngle: .zero,
            endAngle: .degrees(360 * Self.arcLength)
        )
    }

    private func angle(at date: Date) -> Angle {
        let elapsed = date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: Self.period)
        return .degrees(elapsed / Self.period * 360)
    }
}
