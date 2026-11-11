import SwiftUI

/// Scrolls the list of the disk map to the highlighted item each time the highlight moves,
/// so the item pointed at in the rings comes into view.
///
/// It follows the highlight on its own, which leaves the list it's applied to as it was.
struct DiskMapHighlightScrolling: ViewModifier {
    @ObservedObject var highlight: DiskMapHighlight
    let proxy: ScrollViewProxy

    func body(content: Content) -> some View {
        content.onValueChange(of: highlight.itemID) { id in
            guard let id else { return }
            proxy.scrollTo(id)
        }
    }
}
