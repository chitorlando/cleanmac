import SwiftUI

public extension View {
    /// Keeps a scroll view still while everything fits, and lets it bounce once it scrolls.
    ///
    /// The setting arrived in macOS 13.3. Before that the scroll view keeps its default, and
    /// bounces even when all of its content is in view.
    @ViewBuilder
    func scrollBouncesOnlyWhenContentOverflows() -> some View {
        if #available(macOS 13.3, *) {
            scrollBounceBehavior(.basedOnSize)
        } else {
            self
        }
    }
}
