import CleanMacUI
import Foundation
import Testing

@MainActor
struct FeatureItemActionsTests {
    private let documents = URL(filePath: "/Users/test/Documents")
    private let library = URL(filePath: "/Users/test/Library")
    private let app = URL(filePath: "/Applications/Zoom.app")
    private let findDuplicates = FeatureItemAction(featureID: "duplicates", itemKind: .folder, title: "Find Duplicates in Folder", symbolName: "doc.on.doc")
    private let findLargeFiles = FeatureItemAction(featureID: "large-files", itemKind: .folder, title: "Find Large Files in Folder", symbolName: "doc")
    private let uninstall = FeatureItemAction(featureID: "uninstaller", itemKind: .app, title: "Open in Uninstaller", symbolName: "app.badge")

    @Test func offersTheActionsForTheKindOfTheItemInTheirOrder() {
        let actions = FeatureItemActions([findDuplicates, uninstall, findLargeFiles]) { _, _ in true }

        #expect(actions.offered(for: .folder, at: documents) == [findDuplicates, findLargeFiles])
        #expect(actions.offered(for: .app, at: app) == [uninstall])
    }

    @Test func leavesOutTheActionsWhoseFeatureTurnsTheItemDown() {
        let library = library
        let actions = FeatureItemActions([findDuplicates, findLargeFiles]) { action, url in
            !(action.featureID == "duplicates" && url == library)
        }

        #expect(actions.offered(for: .folder, at: library) == [findLargeFiles])
        #expect(actions.offered(for: .folder, at: documents) == [findDuplicates, findLargeFiles])
    }

    @Test func asksOnlyTheFeaturesThatTakeItemsOfThatKind() {
        let actions = FeatureItemActions([findDuplicates, uninstall]) { action, _ in
            #expect(action.itemKind == .app)
            return true
        }

        #expect(actions.offered(for: .app, at: app) == [uninstall])
    }

    @Test func offersNothingOutsideTheAppShell() {
        #expect(FeatureItemActions.none.offered(for: .folder, at: documents).isEmpty)
        #expect(FeatureItemActions.none.offered(for: .app, at: app).isEmpty)
    }
}
