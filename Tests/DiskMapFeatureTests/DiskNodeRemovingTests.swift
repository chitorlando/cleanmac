import DiskMapFeature
import Foundation
import Testing

struct DiskNodeRemovingTests {
    private typealias Fixtures = DiskMapFixtures

    @Test func shrinksEveryFolderAboveTheRemovedItems() throws {
        let map = Fixtures.map.removing([Fixtures.home.appending(path: "Movies/Trips/beach.mov")])
        let movies = try #require(map.children.first { $0.name == "Movies" })
        let trips = try #require(movies.children.first { $0.name == "Trips" })

        #expect(trips.size == 0)
        #expect(trips.children.isEmpty)
        #expect(movies.size == 100)
        #expect(movies.fileCount == 1)
        #expect(map.size == Fixtures.map.size - 400)
        #expect(map.fileCount == Fixtures.map.fileCount - 1)
    }

    @Test func removesWholeFoldersAndKeepsTheLargestFirst() {
        let map = Fixtures.map.removing([Fixtures.home.appending(path: "Movies")])

        #expect(map.children.map(\.name) == ["Library", "Tool.app", "notes.txt"])
        #expect(map.otherItems == Fixtures.map.otherItems)
    }

    @Test func keepsTheFoldersThatCouldNotBeRead() throws {
        let home = Fixtures.home
        let mail = DiskNode(url: home.appending(path: "Library/Mail"), kind: .folder, size: 0, fileCount: 0, isUnreadable: true)
        let cache = Fixtures.file("Library/cache.bin", 50)
        let library = DiskNode(url: home.appending(path: "Library"), kind: .folder, size: 50, fileCount: 1, children: [cache, mail])
        let map = DiskNode(url: home, kind: .folder, size: 50, fileCount: 1, children: [library])

        let shrunk = map.removing([cache.url])
        let keptLibrary = try #require(shrunk.children.first)

        #expect(keptLibrary.children == [mail])
        #expect(keptLibrary.unreadableFolderCount == 1)
        #expect(shrunk.unreadableFolderCount == 1)
    }

    @Test func leavesTheMapAsItIsWithoutMatches() {
        #expect(Fixtures.map.removing([URL(filePath: "/elsewhere")]) == Fixtures.map)
        #expect(Fixtures.map.removing([]) == Fixtures.map)
    }
}
