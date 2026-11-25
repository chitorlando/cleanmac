import CleanMacUI
@testable import DiskMapFeature
import Testing

struct DiskMapItemMenuTests {
    private let duplicates = FeatureItemAction(
        featureID: "duplicates",
        itemKind: .folder,
        title: "Find Duplicates",
        symbolName: "doc.on.doc"
    )
    private let largeFiles = FeatureItemAction(
        featureID: "large-files",
        itemKind: .folder,
        title: "Find Large Files",
        symbolName: "doc"
    )
    private let uninstaller = FeatureItemAction(
        featureID: "uninstaller",
        itemKind: .app,
        title: "Show in Uninstaller",
        symbolName: "app"
    )

    private var featureActions: [FeatureItemAction] { [duplicates, uninstaller, largeFiles] }

    /// A menu offering, for each kind of item, the actions of `featureActions` for that kind.
    private func makeMenu(
        advice: RemovalAdvice,
        canOpen: Bool = false,
        isSelected: Bool = false,
        featureActions: [FeatureItemAction]? = nil
    ) -> DiskMapItemMenu {
        let actions = featureActions ?? self.featureActions
        return DiskMapItemMenu(advice: advice, canOpen: canOpen, isSelected: isSelected) { kind in
            actions.filter { $0.itemKind == kind }
        }
    }

    @Test func offersAFolderToTheFeaturesThatLookIntoFolders() {
        let menu = makeMenu(advice: .allowed, canOpen: true)

        #expect(menu.sections == [
            [.open, .select],
            [.feature(duplicates), .feature(largeFiles)],
            [.showInFinder, .copyPath]
        ])
    }

    @Test func offersAnAppToTheFeaturesThatTakeApps() {
        let menu = makeMenu(advice: .useUninstaller)

        #expect(menu.sections == [
            [.feature(uninstaller)],
            [.showInFinder, .copyPath]
        ])
    }

    @Test func handsAFileToNoFeature() {
        let menu = makeMenu(advice: .allowed)

        #expect(menu.sections == [
            [.select],
            [.showInFinder, .copyPath]
        ])
    }

    @Test func handsAnEmptyFolderToNoFeature() {
        let menu = makeMenu(advice: .standardFolder, canOpen: false)

        #expect(menu.sections == [[.showInFinder, .copyPath]])
    }

    @Test func offersToDeselectASelectedItem() {
        let menu = makeMenu(advice: .allowed, canOpen: true, isSelected: true)

        #expect(menu.sections.first == [.open, .deselect])
    }

    @Test(arguments: [RemovalAdvice.standardFolder, .appData, .protectedData])
    func opensButDoesNotSelectAFolderThatCanNotBeRemoved(advice: RemovalAdvice) {
        let menu = makeMenu(advice: advice, canOpen: true)

        #expect(menu.sections == [
            [.open],
            [.feature(duplicates), .feature(largeFiles)],
            [.showInFinder, .copyPath]
        ])
    }

    @Test func leavesOutTheGroupOfTheFeaturesWhenNoneTakesTheItem() {
        let folder = makeMenu(advice: .allowed, canOpen: true, featureActions: [uninstaller])
        let app = makeMenu(advice: .useUninstaller, featureActions: [])

        #expect(folder.sections == [[.open, .select], [.showInFinder, .copyPath]])
        #expect(app.sections == [[.showInFinder, .copyPath]])
    }

    /// Finding out whether a feature takes the item may look at the disk, so the features are
    /// asked only about the kind of item they would get, and not about a file.
    @Test func asksForTheActionsOfTheKindTheItemGoesAsOnly() {
        var askedKinds: [FeatureItemKind] = []
        let items: [(advice: RemovalAdvice, canOpen: Bool)] = [(.allowed, true), (.useUninstaller, false), (.allowed, false)]

        for item in items {
            _ = DiskMapItemMenu(advice: item.advice, canOpen: item.canOpen, isSelected: false) { kind in
                askedKinds.append(kind)
                return []
            }
        }

        #expect(askedKinds == [.folder, .app])
    }

    @Test func everyCommandOfAMenuHasItsOwnID() {
        let commands = makeMenu(advice: .allowed, canOpen: true).sections.flatMap { $0 }
            + [.deselect, .feature(uninstaller)]

        #expect(Set(commands.map(\.id)).count == commands.count)
    }
}
