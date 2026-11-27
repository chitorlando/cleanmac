import SwiftUI

extension View {
    /// Makes a large symbol answer the pointer: on macOS 14 and later, it bounces when the
    /// pointer comes over it; before, it leans and grows a little while the pointer is on it.
    /// With Reduce Motion on, it stays still.
    func reactsToHover() -> some View {
        modifier(HoverReaction())
    }
}

private struct HoverReaction: ViewModifier {
    private static let lean: Double = -6
    private static let growth: CGFloat = 1.06

    @Environment(\.motionPolicy) private var motion
    @State private var isHovered = false
    /// How many times the pointer came over the symbol, which bounces each time.
    @State private var arrivals = 0

    func body(content: Content) -> some View {
        reacting(content)
            .onHover { isInside in
                isHovered = isInside
                if isInside {
                    arrivals += 1
                }
            }
    }

    @ViewBuilder
    private func reacting(_ content: Content) -> some View {
        if motion.allowsTravel {
            if #available(macOS 14, *) {
                content.symbolEffect(.bounce, value: arrivals)
            } else {
                content
                    .scaleEffect(isHovered ? Self.growth : 1)
                    .rotationEffect(.degrees(isHovered ? Self.lean : 0))
                    .animation(Motion.pop, value: isHovered)
            }
        } else {
            content
        }
    }
}
