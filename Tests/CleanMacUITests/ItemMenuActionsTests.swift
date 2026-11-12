import CleanMacUI
import Foundation
import Testing

struct ItemMenuActionsTests {
    private let file = URL(filePath: "/Users/test/report.pdf")
    private let app = URL(filePath: "/Applications/Zoom.app")

    @Test func offersEveryCommonActionForASelectableFile() {
        #expect(ItemMenuActions.standard(for: file, selection: .deselected) == [.showInFinder, .open, .copyPath, .select])
    }

    @Test func offersDeselectForASelectedItem() {
        #expect(ItemMenuActions.standard(for: file, selection: .selected).last == .deselect)
    }

    @Test func lockedItemsOfferNeitherSelectNorDeselect() {
        let actions = ItemMenuActions.standard(for: file, selection: .unavailable)

        #expect(actions == [.showInFinder, .open, .copyPath])
    }

    @Test func neverOffersToOpenAnApp() {
        #expect(!ItemMenuActions.standard(for: app, selection: .deselected).contains(.open))
        #expect(!ItemMenuActions.standard(for: URL(filePath: "/Applications/Old.APP"), selection: .deselected).contains(.open))
    }

    @Test func leavesOpeningToTheFeatureWhenAsked() {
        #expect(ItemMenuActions.standard(for: file, canOpen: false, selection: .deselected) == [.showInFinder, .copyPath, .select])
    }

    @Test func neverOffersToRemoveAnything() {
        let all = [ItemMenuSelection.unavailable, .selected, .deselected].flatMap {
            ItemMenuActions.standard(for: file, selection: $0)
        }

        #expect(Set(all).isSubset(of: [.showInFinder, .open, .copyPath, .select, .deselect]))
    }

    @Test func selectionFollowsTheItemAndItsLock() {
        #expect(ItemMenuSelection(isSelected: true, canChange: true) == .selected)
        #expect(ItemMenuSelection(isSelected: false, canChange: true) == .deselected)
        #expect(ItemMenuSelection(isSelected: true, canChange: false) == .unavailable)
    }
}

@MainActor
struct ItemMenuActionPerformTests {
    private let file = URL(filePath: "/Users/test/report.pdf")

    @Test(arguments: [ItemMenuAction.showInFinder, .open, .copyPath])
    func fileActionsGoToTheFileActions(action: ItemMenuAction) {
        let files = RecordingFileActions()
        var toggles = 0

        action.perform(on: file, files: files) { toggles += 1 }

        let expected: RecordingFileActions.Call = switch action {
        case .showInFinder: .showInFinder(file)
        case .open: .open(file)
        default: .copyPath(file)
        }
        #expect(files.calls == [expected])
        #expect(toggles == 0)
    }

    @Test(arguments: [ItemMenuAction.select, .deselect])
    func selectingGoesThroughTheFeature(action: ItemMenuAction) {
        let files = RecordingFileActions()
        var toggles = 0

        action.perform(on: file, files: files) { toggles += 1 }

        #expect(toggles == 1)
        #expect(files.calls.isEmpty)
    }
}
