import SwiftUI

/// Gradient button with a soft glow, in a circular or capsule shape.
///
/// Under the pointer it brightens, grows a little and glows more; pressed, it shrinks. With
/// Reduce Motion on, it only brightens under the pointer and darkens when pressed.
public struct GlowButtonStyle: ButtonStyle {
    public enum Shape: Sendable {
        case circle(diameter: CGFloat)
        case capsule
    }

    private let theme: FeatureTheme
    private let shape: Shape

    public init(theme: FeatureTheme, shape: Shape) {
        self.theme = theme
        self.shape = shape
    }

    public func makeBody(configuration: Configuration) -> some View {
        GlowButton(label: configuration.label, isPressed: configuration.isPressed, theme: theme, shape: shape)
    }
}

/// A glow button, which follows the pointer to answer it.
private struct GlowButton: View {
    /// How much brighter the button gets under the pointer, and darker when pressed with
    /// Reduce Motion on, where it doesn't shrink.
    private static let hoverBrightness = 0.06
    private static let pressBrightness = -0.12

    let label: ButtonStyleConfiguration.Label
    let isPressed: Bool
    let theme: FeatureTheme
    let shape: GlowButtonStyle.Shape
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.motionPolicy) private var motion
    @State private var isHovered = false

    var body: some View {
        styled
            .font(.system(.title3, design: .rounded, weight: .semibold))
            .foregroundStyle(Palette.canvas)
            .glow(theme.primary.opacity(glowOpacity), radius: isHighlighted ? 30 : 22)
            .scaleEffect(scale)
            .brightness(brightness)
            .opacity(isEnabled ? 1 : 0.4)
            .animation(Motion.press, value: isPressed)
            .animation(Motion.feedback, value: isHovered)
            .contentShape(.rect)
            .onHover { isHovered = $0 }
    }

    @ViewBuilder
    private var styled: some View {
        switch shape {
        case .circle(let diameter):
            label
                .frame(width: diameter, height: diameter)
                .background(theme.gradient, in: .circle)
                .overlay(Circle().strokeBorder(.white.opacity(0.25), lineWidth: 1))
                // The round button that starts a feature grows into the ring of what it starts.
                .phaseFocus()
        case .capsule:
            label
                .padding(.horizontal, 32)
                .padding(.vertical, 14)
                .background(theme.gradient, in: .pill)
                .overlay(Capsule.pill.strokeBorder(.white.opacity(0.25), lineWidth: 1))
        }
    }

    /// Whether the pointer is over the button, which could be clicked.
    private var isHighlighted: Bool {
        isEnabled && isHovered && !isPressed
    }

    private var glowOpacity: Double {
        guard isEnabled else { return 0 }
        return isHighlighted ? 0.75 : 0.55
    }

    private var scale: CGFloat {
        guard motion.allowsTravel else { return 1 }
        if isPressed { return Motion.pressScale }
        return isHighlighted ? Motion.hoverScale : 1
    }

    private var brightness: Double {
        if isPressed { return motion.allowsTravel ? 0 : Self.pressBrightness }
        return isHighlighted ? Self.hoverBrightness : 0
    }
}
