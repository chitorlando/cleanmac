import SwiftUI

/// Transition between the phases of a feature screen, such as scanning and review.
///
/// Cross-fades with a subtle zoom, or only cross-fades when Reduce Motion is on.
struct PhaseTransition: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content.transition(reduceMotion ? .opacity : .opacity.combined(with: .scale(scale: 0.98)))
    }
}

public extension View {
    /// Applies the standard transition used when a feature screen changes phase.
    func phaseTransition() -> some View {
        modifier(PhaseTransition())
    }
}
