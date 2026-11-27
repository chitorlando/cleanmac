import SwiftUI

public extension View {
    /// Surrounds the view with a soft glow of `color`, left out while Reduce Transparency is on.
    func glow(_ color: Color, radius: CGFloat) -> some View {
        modifier(Glow(color: color, radius: radius))
    }
}

/// Soft glow around a view, which gives way to its plain shape while Reduce Transparency is on.
private struct Glow: ViewModifier {
    let color: Color
    let radius: CGFloat
    @Environment(\.motionPolicy) private var motion

    func body(content: Content) -> some View {
        // A clear shadow keeps the view the same, so turning the setting on or off doesn't
        // build it again.
        content.shadow(
            color: motion.drawsGlows ? color : .clear,
            radius: motion.drawsGlows ? radius : 0
        )
    }
}
