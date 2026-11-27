import SwiftUI

/// Round badge in the feature's colors whose checkmark draws itself once the badge pops in.
/// When it `celebrates`, a soft burst spreads around it, once.
///
/// On a screen of a finished task, it's the circle the screen centers on, so it grows out of
/// the ring of the task (see `phaseFocus()`). With Reduce Motion on, the badge and its
/// checkmark appear without popping, drawing or bursting. With Reduce Transparency on, it has
/// no glow. VoiceOver skips it: the text next to it says what happened.
public struct SuccessBadge: View {
    private let theme: FeatureTheme
    private let diameter: CGFloat
    private let celebrates: Bool

    @Environment(\.motionPolicy) private var motion
    @State private var hasAppeared = false
    @State private var isChecked = false

    /// - Parameters:
    ///   - diameter: The size of the badge, which its checkmark and glow follow.
    ///   - celebrates: Whether a burst spreads around the badge when it appears.
    public init(theme: FeatureTheme, diameter: CGFloat, celebrates: Bool = false) {
        self.theme = theme
        self.diameter = diameter
        self.celebrates = celebrates
    }

    public var body: some View {
        ZStack {
            if celebrates && motion.animatesDecorations {
                SuccessBurst(theme: theme, isPlaying: hasAppeared)
            }
            badge
        }
        .phaseFocus()
        .frame(width: diameter, height: diameter)
        .accessibilityHidden(true)
        .onAppear(perform: appear)
    }

    private var badge: some View {
        Circle()
            .fill(theme.gradient)
            .overlay(Circle().strokeBorder(.white.opacity(0.25), lineWidth: 1))
            .overlay(
                CheckmarkShape()
                    .trim(from: 0, to: isChecked || !motion.allowsTravel ? 1 : 0)
                    .stroke(
                        Palette.canvas,
                        style: StrokeStyle(lineWidth: diameter * 0.09, lineCap: .round, lineJoin: .round)
                    )
            )
            .glow(theme.primary.opacity(0.6), radius: diameter / 4)
            .modifier(BadgePop(hasAppeared: hasAppeared, allowsTravel: motion.allowsTravel))
    }

    private func appear() {
        guard !hasAppeared else { return }
        withAnimation(Motion.pop) { hasAppeared = true }
        withAnimation(Motion.checkmark) { isChecked = true }
    }
}

/// Pops the badge in: it starts a little small, overshoots and settles. macOS 14 and later play
/// it as keyframes, for a crisper overshoot; earlier systems spring into place.
private struct BadgePop: ViewModifier {
    /// How big the badge starts, compared to its size.
    private static let startScale: CGFloat = 0.75

    let hasAppeared: Bool
    let allowsTravel: Bool

    func body(content: Content) -> some View {
        if allowsTravel {
            if #available(macOS 14, *) {
                let startScale = Self.startScale
                content.keyframeAnimator(initialValue: CGFloat(1), trigger: hasAppeared) { view, scale in
                    view.scaleEffect(scale)
                } keyframes: { _ in
                    KeyframeTrack {
                        MoveKeyframe(startScale)
                        SpringKeyframe(1.08, duration: 0.25, spring: .snappy)
                        SpringKeyframe(1, duration: 0.35, spring: .bouncy)
                    }
                }
            } else {
                content.scaleEffect(hasAppeared ? 1 : Self.startScale)
            }
        } else {
            content
        }
    }
}
