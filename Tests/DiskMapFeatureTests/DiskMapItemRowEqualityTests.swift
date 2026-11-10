import CleanMacUI
@testable import DiskMapFeature
import SwiftUI
import Testing

@MainActor
struct DiskMapItemRowEqualityTests {
    private func row(_ name: String = "notes.txt", isSelected: Bool = false, isHighlighted: Bool = false) -> DiskMapItemRow {
        DiskMapItemRow(
            node: DiskMapFixtures.file(name, 30),
            share: 0.25,
            color: .blue,
            advice: .allowed,
            isSelected: isSelected,
            isHighlighted: isHighlighted,
            canOpen: false,
            theme: .neutral,
            onToggle: {},
            onOpen: {}
        )
    }

    @Test func rowsThatShowTheSameAreEqualWhateverTheirActions() {
        let first = row()
        let second = row()

        #expect(first == second)
    }

    @Test func tellsRowsApartByTheHighlight() {
        let plain = row()
        let highlighted = row(isHighlighted: true)

        #expect(plain != highlighted)
    }

    @Test func tellsRowsApartByTheSelection() {
        let plain = row()
        let selected = row(isSelected: true)

        #expect(plain != selected)
    }

    @Test func tellsRowsApartByTheirItem() {
        let notes = row("notes.txt")
        let other = row("other.txt")

        #expect(notes != other)
    }
}
