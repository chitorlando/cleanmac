import Foundation
import Testing
import UninstallerFeature

struct LeftoverCatalogTests {
    private let home = URL(filePath: "/Users/tester")

    @Test func onlyLooksInsideTheUserLibrary() {
        let library = home.appending(path: "Library").path + "/"
        let locations = LeftoverCatalog.userLocations(home: home)

        #expect(!locations.isEmpty)
        #expect(locations.allSatisfy { $0.url.path.hasPrefix(library) })
    }

    @Test func coversEveryLeftoverKind() {
        let kinds = Set(LeftoverCatalog.userLocations(home: home).map(\.kind))
        #expect(kinds == Set(LeftoverKind.allCases))
    }

    @Test func matchesGroupContainersOnlyByTheirSuffix() throws {
        let groups = try #require(LeftoverCatalog.userLocations(home: home).first { $0.kind == .groupContainers })
        #expect(groups.rules == [.groupContainer])
    }
}
