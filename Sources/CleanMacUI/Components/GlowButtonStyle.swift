import SwiftUI

/// Gradient button with a soft glow, in a circular or capsule shape.
public struct GlowButtonStyle: ButtonStyle {
    public enum Shape: Sendable {
        case circle(diameter: CGFloat)
        case capsule
    }

    private let theme: FeatureTheme
    private let shape: Shape
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(theme: FeatureTheme, shape: Shape) {
        self.theme = theme
        self.shape = shape
    }

    public func makeBody(configuration: Configuration) -> some View {
        styled(configuration.label)
            .font(.system(.title3, design: .rounded, weight: .semibold))
            .foregroundStyle(Palette.canvas)
            .shadow(color: theme.primary.opacity(isEnabled ? 0.55 : 0), radius: 22)
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.95 : 1)
            .brightness(configuration.isPressed && reduceMotion ? -0.12 : 0)
            .opacity(isEnabled ? 1 : 0.4)
            .animation(.snappy(duration: 0.2), value: configuration.isPressed)
            .contentShape(.rect)
    }

    @ViewBuilder
    private func styled(_ label: Configuration.Label) -> some View {
        switch shape {
        case .circle(let diameter):
            label
                .frame(width: diameter, height: diameter)
                .background(theme.gradient, in: .circle)
                .overlay(Circle().strokeBorder(.white.opacity(0.25), lineWidth: 1))
        case .capsule:
            label
                .padding(.horizontal, 32)
                .padding(.vertical, 14)
                .background(theme.gradient, in: .pill)
                .overlay(Capsule.pill.strokeBorder(.white.opacity(0.25), lineWidth: 1))
        }
    }
}
