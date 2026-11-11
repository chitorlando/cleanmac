import SwiftUI

/// Rows are equal when they show the same thing.
///
/// Every move of the highlight redraws the list, and a row holds closures, which SwiftUI
/// can't compare, so it used to evaluate every row on screen again. With this it skips the
/// rows that didn't change. Their actions are left out of the comparison: those of a row
/// always act on its own item.
extension DiskMapItemRow: Equatable {
    nonisolated static func == (lhs: DiskMapItemRow, rhs: DiskMapItemRow) -> Bool {
        lhs.isHighlighted == rhs.isHighlighted
            && lhs.isSelected == rhs.isSelected
            && lhs.canOpen == rhs.canOpen
            && lhs.canShowInUninstaller == rhs.canShowInUninstaller
            && lhs.advice == rhs.advice
            && lhs.share == rhs.share
            && lhs.color == rhs.color
            && lhs.theme.primary == rhs.theme.primary
            && lhs.theme.secondary == rhs.theme.secondary
            && lhs.node == rhs.node
    }
}
