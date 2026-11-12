import CleanMacUI
@testable import DuplicatesFeature
import SwiftUI
import Testing

@MainActor
struct DuplicateCopyRowEqualityTests {
    /// - Parameter linkCount: Names the file has on its volume: more than one shows the hard link badge.
    private func row(
        linkCount: Int = 1,
        isSelected: Bool = false,
        canSelect: Bool = true,
        isSuggestedKeeper: Bool = false,
        isClone: Bool = false
    ) -> DuplicateCopyRow {
        DuplicateCopyRow(
            file: DuplicateFixtures.file("/Users/test/report.pdf", linkCount: linkCount),
            isSelected: isSelected,
            canSelect: canSelect,
            isSuggestedKeeper: isSuggestedKeeper,
            isClone: isClone,
            theme: .neutral,
            onToggle: {}
        )
    }

    @Test func rowsThatShowTheSameAreEqualWhateverTheirActions() {
        let first = row()
        let second = row()

        #expect(first == second)
    }

    // The hard link badge comes from the file, so the comparison must tell its names apart.
    @Test func tellsRowsApartByTheOtherNamesOfTheirFile() {
        let plain = row()
        let linked = row(linkCount: 2)

        #expect(plain != linked)
    }

    @Test func tellsRowsApartByTheSelection() {
        let plain = row()
        let selected = row(isSelected: true)

        #expect(plain != selected)
    }

    @Test func tellsRowsApartByWhetherTheyCanBeSelected() {
        let plain = row()
        let locked = row(canSelect: false)

        #expect(plain != locked)
    }

    @Test func tellsRowsApartByTheSuggestionToKeep() {
        let plain = row()
        let keeper = row(isSuggestedKeeper: true)

        #expect(plain != keeper)
    }

    @Test func tellsRowsApartByTheCloneBadge() {
        let plain = row()
        let clone = row(isClone: true)

        #expect(plain != clone)
    }
}
