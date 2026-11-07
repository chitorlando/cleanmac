import CleanMacCore
import Foundation
import Testing

struct LocalVolumeResolverTests {
    @Test func resolvesTheStartupVolumeToTheRoot() {
        #expect(LocalVolumeResolver().volume(containing: URL(filePath: "/"))?.path == "/")
    }

    @Test func resolvesTheVolumeOfAnExistingFolder() {
        #expect(LocalVolumeResolver().volume(containing: FileManager.default.temporaryDirectory) != nil)
    }

    @Test func returnsNilForMissingItems() {
        #expect(LocalVolumeResolver().volume(containing: URL(filePath: "/nonexistent/item")) == nil)
    }
}
