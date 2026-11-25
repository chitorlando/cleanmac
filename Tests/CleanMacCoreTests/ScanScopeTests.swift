import CleanMacCore
import Foundation
import Testing

struct ScanScopeTests {
    private let downloads = URL(filePath: "/Users/test/Downloads")

    @Test func theWholeHomeFolderIsLimitedToNoFolder() {
        #expect(ScanScope.home.folder == nil)
    }

    @Test func aFolderScopeIsLimitedToItsFolder() {
        #expect(ScanScope.folder(downloads).folder == downloads)
    }

    @Test func scopesAreEqualWhenTheyCoverTheSame() {
        #expect(ScanScope.folder(downloads) == .folder(downloads))
        #expect(ScanScope.folder(downloads) != .folder(URL(filePath: "/Users/test/Movies")))
        #expect(ScanScope.folder(downloads) != .home)
    }
}
