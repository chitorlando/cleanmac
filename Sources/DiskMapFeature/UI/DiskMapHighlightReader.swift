import SwiftUI

/// Hands its content the highlighted item, and builds that content again each time the
/// highlight moves.
///
/// It's how a view follows the highlight without the view around it doing so: whatever else
/// the content shows was worked out when the view around it was last evaluated, and a move of
/// the highlight only builds the content again with those same values.
struct DiskMapHighlightReader<Content: View>: View {
    @ObservedObject var highlight: DiskMapHighlight
    /// Gets the highlighted item, or `nil` when there's none.
    @ViewBuilder let content: (DiskNode.ID?) -> Content

    var body: some View {
        content(highlight.itemID)
    }
}
