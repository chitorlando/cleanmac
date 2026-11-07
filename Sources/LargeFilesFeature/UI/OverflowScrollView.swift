import SwiftUI

/// Shows its content at its natural height when there's room, and scrolling when there isn't.
///
/// When it starts scrolling it brings the view with `revealedID` into sight,
/// so a chosen option is never left hidden below the edge.
struct OverflowScrollView<Content: View, ID: Hashable>: View {
    private static var minimumHeight: CGFloat { 44 }

    let revealedID: ID?
    @ViewBuilder let content: Content

    var body: some View {
        ViewThatFits(in: .vertical) {
            content
            ScrollViewReader { proxy in
                ScrollView {
                    content
                }
                .frame(minHeight: Self.minimumHeight)
                .onAppear {
                    if let revealedID {
                        proxy.scrollTo(revealedID)
                    }
                }
            }
        }
    }
}
