import SwiftUI

/// Draws its content again for each frame of the display, but only while the window that holds
/// it is shown: it stops while the window is minimized, closed or its app hidden, and once the
/// view leaves the screen, so nothing animates out of sight.
struct AnimationFrames<Content: View>: View {
    private let minimumInterval: TimeInterval?
    private let content: (Date) -> Content
    @State private var isWindowShown = false

    /// - Parameters:
    ///   - minimumInterval: The shortest time between two frames, to draw less often than the
    ///     display refreshes, or `nil` to draw on every refresh.
    ///   - content: What to draw at a given moment.
    init(minimumInterval: TimeInterval? = nil, @ViewBuilder content: @escaping (Date) -> Content) {
        self.minimumInterval = minimumInterval
        self.content = content
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: minimumInterval, paused: !isWindowShown)) { context in
            content(context.date)
        }
        .onWindowVisibilityChange { isShown in
            // The window tells while SwiftUI adds the view to it, so the change waits for the
            // next turn instead of modifying state in the middle of an update.
            Task { @MainActor in
                isWindowShown = isShown
            }
        }
    }
}
