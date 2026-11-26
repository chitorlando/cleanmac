import CleanMacUI
import Foundation
import Testing

/// The checks hold in any language the tests run in.
struct EmptyTrashConfirmationTextTests {
    private let trashSize: Int64 = 3_400_000_000
    private let sizeToMove: Int64 = 1_200_000_000

    @Test func emptyingAloneSaysOnlyWhatIsErased() {
        let text = EmptyTrashConfirmationText(trashSize: trashSize)

        #expect(text.message.contains(trashSize.formattedByteCount))
        #expect(!text.message.contains(sizeToMove.formattedByteCount))
        #expect(!text.title.isEmpty)
        #expect(!text.confirmTitle.isEmpty)
    }

    @Test func aMixedSelectionSaysWhatIsErasedAndThenWhatCanBePutBack() {
        let erasing = EmptyTrashConfirmationText(trashSize: trashSize)

        let mixed = EmptyTrashConfirmationText(trashSize: trashSize, itemsToMove: 4, sizeToMove: sizeToMove)

        #expect(mixed.message.hasPrefix(erasing.message))
        #expect(mixed.message.contains(sizeToMove.formattedByteCount))
        #expect(mixed.title != erasing.title)
        #expect(mixed.title.contains("4"))
        #expect(mixed.confirmTitle != erasing.confirmTitle)
    }

    @Test func saysNothingAboutMovingWhenNothingMoves() {
        let erasing = EmptyTrashConfirmationText(trashSize: trashSize)

        #expect(EmptyTrashConfirmationText(trashSize: trashSize, itemsToMove: 0, sizeToMove: sizeToMove) == erasing)
    }
}
