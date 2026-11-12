import CleanMacUI
import Testing

struct FeatureItemActionTests {
    @Test func aFeatureHasADifferentActionForEachKindOfItem() {
        let forFolders = FeatureItemAction(featureID: "duplicates", itemKind: .folder, title: "Folder", symbolName: "folder")
        let forApps = FeatureItemAction(featureID: "duplicates", itemKind: .app, title: "App", symbolName: "app")

        #expect(forFolders.id != forApps.id)
    }

    @Test func twoFeaturesHaveDifferentActionsForTheSameKindOfItem() {
        let duplicates = FeatureItemAction(featureID: "duplicates", itemKind: .folder, title: "Folder", symbolName: "folder")
        let largeFiles = FeatureItemAction(featureID: "large-files", itemKind: .folder, title: "Folder", symbolName: "folder")

        #expect(duplicates.id != largeFiles.id)
    }
}
