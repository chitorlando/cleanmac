import SwiftUI

extension View {
    /// Switches selection off for a list row, on the systems that can do it row by row.
    ///
    /// That arrived in macOS 14. Earlier systems ignore it, so there a row only stays out of
    /// the selection when its identity isn't of the type the list selects, as with
    /// `UpcomingFeature.ID`.
    @ViewBuilder
    func selectionDisabledWhereSupported() -> some View {
        if #available(macOS 14, *) {
            selectionDisabled()
        } else {
            self
        }
    }
}
