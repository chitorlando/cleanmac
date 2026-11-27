import SwiftUI

/// Transition between the phases of a feature screen, such as scanning and review.
///
/// The new phase fades in as it rises into place, while the old one fades out, sinking back a
/// little. Meanwhile the circle both phases center on, such as the scan button and the ring of
/// the scan, grows from one into the other (see `phaseFocus()`). With Reduce Motion on, the
/// phases only cross-fade.
struct PhaseTransition: ViewModifier {
    @Environment(\.motionPolicy) private var motion

    func body(content: Content) -> some View {
        content.transition(motion.allowsTravel ? Self.rising : .opacity)
    }

    private static var rising: AnyTransition {
        .asymmetric(
            insertion: .opacity
                .combined(with: .offset(y: Motion.phaseRise))
                .combined(with: .scale(scale: 0.98)),
            removal: .opacity.combined(with: .scale(scale: 0.97))
        )
    }
}

public extension View {
    /// Applies the standard transition used when a feature screen changes phase.
    func phaseTransition() -> some View {
        modifier(PhaseTransition())
    }
}
