import SwiftUI

public extension View {
    /// Lets the rows and cards inside enter one after the other the first time the view
    /// appears, each in the turn `staggeredEntrance(order:)` gives it.
    func revealsRowsInTurn() -> some View {
        modifier(RowReveal())
    }

    /// Makes a row or card of a list enter in its turn: the first time the list appears, it
    /// fades in as it rises into place, a moment after the row before it. Rows that come into
    /// view later, such as when the list scrolls, are simply there. A row that leaves the list
    /// during an animation slides away to the side as it fades.
    ///
    /// The list reveals its rows with `revealsRowsInTurn()`; without it, rows are simply there.
    /// With Reduce Motion on, every row fades in at once, and fades out when it leaves.
    ///
    /// - Parameter order: The position of the row in the list, from 0.
    func staggeredEntrance(order: Int) -> some View {
        modifier(StaggeredEntrance(order: order))
    }
}

private extension EnvironmentValues {
    /// Whether the rows of the list the view is in have entered. Rows of a list that doesn't
    /// reveal them in turn are always in.
    var areRowsRevealed: Bool {
        get { self[RowsRevealedKey.self] }
        set { self[RowsRevealedKey.self] = newValue }
    }
}

private struct RowsRevealedKey: EnvironmentKey {
    static let defaultValue = true
}

/// Reveals the rows inside once, when the view first appears.
private struct RowReveal: ViewModifier {
    @State private var isRevealed = false

    func body(content: Content) -> some View {
        content
            .environment(\.areRowsRevealed, isRevealed)
            .onAppear { isRevealed = true }
    }
}

/// Fades a row in, rising, in its turn once its list reveals its rows.
private struct StaggeredEntrance: ViewModifier {
    let order: Int
    @Environment(\.areRowsRevealed) private var isRevealed
    @Environment(\.motionPolicy) private var motion

    func body(content: Content) -> some View {
        content
            .opacity(isRevealed ? 1 : 0)
            .offset(y: isRevealed ? 0 : motion.entranceRise)
            .animation(Motion.entrance.delay(motion.entranceDelay(forRowAt: order)), value: isRevealed)
            .transition(motion.allowsTravel ? Self.slidingAway : .opacity)
    }

    /// A row added to the list fades in, and a row that leaves slides away to the side as it fades.
    private static var slidingAway: AnyTransition {
        .asymmetric(insertion: .opacity, removal: .move(edge: .trailing).combined(with: .opacity))
    }
}
