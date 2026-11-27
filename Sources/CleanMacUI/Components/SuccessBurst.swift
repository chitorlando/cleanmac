import SwiftUI

/// A soft burst around the badge of a finished task: a ring that spreads out and fades, and
/// short sparks in the feature's colors flying out from behind the badge. It plays once, when
/// `isPlaying` turns on, and leaves nothing on screen afterwards.
struct SuccessBurst: View {
    private static let sparkCount = 10

    let theme: FeatureTheme
    let isPlaying: Bool

    var body: some View {
        GeometryReader { proxy in
            let diameter = min(proxy.size.width, proxy.size.height)
            ZStack {
                Circle()
                    .stroke(theme.gradient, lineWidth: 2)
                    .scaleEffect(isPlaying ? 1.9 : 1)
                    .opacity(isPlaying ? 0 : 0.8)
                ForEach(0..<Self.sparkCount, id: \.self) { index in
                    spark(index, diameter: diameter)
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .animation(Motion.burst, value: isPlaying)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    /// A short dash that flies straight out from the center and fades, one of several spread
    /// evenly around it.
    private func spark(_ index: Int, diameter: CGFloat) -> some View {
        Capsule()
            .fill(index.isMultiple(of: 2) ? theme.primary : theme.secondary)
            .frame(width: diameter * 0.035, height: diameter * 0.12)
            .offset(y: -diameter * (isPlaying ? 0.95 : 0.42))
            .opacity(isPlaying ? 0 : 1)
            .rotationEffect(.degrees(Double(index) / Double(Self.sparkCount) * 360))
    }
}
