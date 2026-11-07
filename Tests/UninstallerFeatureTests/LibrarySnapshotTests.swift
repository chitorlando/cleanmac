import Foundation
import Testing
import UninstallerFeature

struct LibrarySnapshotTests {
    @Test func listsTheChildrenOfExistingLocations() {
        let caches = LeftoverLocation(url: URL(filePath: "/home/Library/Caches"), kind: .caches, rules: [.bundleID])
        let missing = LeftoverLocation(url: URL(filePath: "/home/Library/Missing"), kind: .logs, rules: [.bundleID])
        let child = caches.url.appending(path: "com.foo.app")

        let snapshot = LibrarySnapshot(
            locations: [caches, missing],
            reader: FakeDirectoryReader(tree: [caches.url: [child]])
        )

        #expect(snapshot.candidates == [LeftoverCandidate(url: child, location: caches)])
    }
}
