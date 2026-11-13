import CleanMacUI
import Foundation
import Testing

struct ItemMenuTests {
    private let file = URL(filePath: "/Users/test/Downloads/report.pdf")
    private let folder = URL(filePath: "/Users/test/Projects")
    private let app = URL(filePath: "/Applications/Zoom.app")
    private let findDuplicates = FeatureItemAction(featureID: "duplicates", itemKind: .folder, title: "Find Duplicates in Folder", symbolName: "doc.on.doc")
    private let uninstall = FeatureItemAction(featureID: "uninstaller", itemKind: .app, title: "Open in Uninstaller", symbolName: "app.badge")

    private func menu(_ url: URL, isFolder: Bool = false, canOpen: Bool = true, selection: ItemMenuSelection = .deselected) -> ItemMenu {
        ItemMenu(url: url, isFolder: isFolder, canOpen: canOpen, selection: selection, featureActions: [findDuplicates, uninstall])
    }

    @Test func groupsTheRowsOwnActionsTheOtherFeaturesAndTheCommonOnes() {
        #expect(menu(folder, isFolder: true).sections == [
            [.open, .select],
            [.feature(findDuplicates, target: folder)],
            [.showInFinder, .copyPath]
        ])
    }

    @Test func offersDeselectForASelectedItem() {
        #expect(menu(file, selection: .selected).sections.first == [.open, .deselect])
    }

    @Test func lockedItemsOfferNeitherSelectNorDeselect() {
        #expect(menu(file, selection: .unavailable).sections.first == [.open])
        #expect(menu(file, canOpen: false, selection: .unavailable).sections.first == [.feature(findDuplicates, target: file.deletingLastPathComponent())])
    }

    @Test func appsGoToTheFeaturesThatTakeAppsAndAreNeverOpened() {
        #expect(menu(app).sections == [
            [.select],
            [.feature(uninstall, target: app)],
            [.showInFinder, .copyPath]
        ])
    }

    @Test func aFileOffersTheFolderActionsForItsFolder() {
        #expect(menu(file).sections[1] == [.feature(findDuplicates, target: URL(filePath: "/Users/test/Downloads/"))])
    }

    @Test func withoutOtherFeaturesTheirGroupIsLeftOut() {
        let menu = ItemMenu(url: file, selection: .deselected, featureActions: [])

        #expect(menu.sections == [[.open, .select], [.showInFinder, .copyPath]])
    }

    @Test func neverOffersToRemoveAnything() {
        let all = [ItemMenuSelection.unavailable, .selected, .deselected]
            .flatMap { menu(file, selection: $0).sections.joined() }

        #expect(all.allSatisfy { action in
            switch action {
            case .open, .select, .deselect, .showInFinder, .copyPath, .feature: true
            }
        })
        #expect(!all.contains { $0.id.localizedCaseInsensitiveContains("trash") })
    }

    @Test func selectionFollowsTheItemAndItsLock() {
        #expect(ItemMenuSelection(isSelected: true, canChange: true) == .selected)
        #expect(ItemMenuSelection(isSelected: false, canChange: true) == .deselected)
        #expect(ItemMenuSelection(isSelected: true, canChange: false) == .unavailable)
    }
}

struct FeatureItemTargetTests {
    @Test func anAppIsHandedAsAnApp() {
        let target = FeatureItemTarget(itemAt: URL(filePath: "/Applications/Zoom.APP"), isFolder: true)

        #expect(target.kind == .app)
        #expect(target.url == URL(filePath: "/Applications/Zoom.APP"))
    }

    @Test func aFolderIsHandedAsItself() {
        let folder = URL(filePath: "/Users/test/Projects")

        #expect(FeatureItemTarget(itemAt: folder, isFolder: true) == FeatureItemTarget(itemAt: folder, isFolder: true))
        #expect(FeatureItemTarget(itemAt: folder, isFolder: true).url == folder)
        #expect(FeatureItemTarget(itemAt: folder, isFolder: true).kind == .folder)
    }

    @Test func aFileIsHandedAsItsFolder() {
        let target = FeatureItemTarget(itemAt: URL(filePath: "/Users/test/Movies/trip.mov"), isFolder: false)

        #expect(target.kind == .folder)
        #expect(target.url.path == "/Users/test/Movies")
    }
}

@MainActor
struct ItemMenuActionPerformTests {
    private let file = URL(filePath: "/Users/test/report.pdf")

    private final class OpenedFeatures {
        var requests: [(String, URL?)] = []
    }

    private func perform(_ action: ItemMenuAction) -> (RecordingFileActions, [(String, URL?)], Int) {
        let files = RecordingFileActions()
        let opened = OpenedFeatures()
        var toggles = 0
        let openFeature = OpenFeatureAction { id, url in opened.requests.append((id, url)) }
        action.perform(on: file, files: files, openFeature: openFeature) { toggles += 1 }
        return (files, opened.requests, toggles)
    }

    @Test func fileActionsGoToTheFileActions() {
        #expect(perform(.showInFinder).0.calls == [.showInFinder(file)])
        #expect(perform(.open).0.calls == [.open(file)])
        #expect(perform(.copyPath).0.calls == [.copyPath(file)])
        #expect(perform(.copyPath).2 == 0)
    }

    @Test(arguments: [ItemMenuAction.select, .deselect])
    func selectingGoesThroughTheFeature(action: ItemMenuAction) {
        let (files, requests, toggles) = perform(action)

        #expect(toggles == 1)
        #expect(files.calls.isEmpty && requests.isEmpty)
    }

    @Test func anotherFeaturesActionOpensItWithTheTarget() {
        let folder = URL(filePath: "/Users/test")
        let action = FeatureItemAction(featureID: "duplicates", itemKind: .folder, title: "Find", symbolName: "doc")

        let (files, requests, toggles) = perform(.feature(action, target: folder))

        #expect(requests.map(\.0) == ["duplicates"])
        #expect(requests.map(\.1) == [folder])
        #expect(files.calls.isEmpty && toggles == 0)
    }
}
