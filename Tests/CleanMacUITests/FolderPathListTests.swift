@testable import CleanMacUI
import Foundation
import Testing

struct FolderPathListTests {
    private let movies = URL(filePath: "/Users/test/Movies")
    private let music = URL(filePath: "/Users/test/Music")

    @Test func keepsEachPathOnceInTheOrderGiven() {
        let list = FolderPathList(["/Users/test/Music", "/Users/test/Movies", "/Users/test/Music"])

        #expect(list.paths == ["/Users/test/Music", "/Users/test/Movies"])
    }

    @Test func addsTheChosenFoldersAtTheEnd() {
        var list = FolderPathList(["/Users/test/Music"])

        let refused = list.add([movies], as: { $0 })

        #expect(list.paths == ["/Users/test/Music", "/Users/test/Movies"])
        #expect(refused.isEmpty)
    }

    @Test func addsAFolderAlreadyInTheListOnlyOnce() {
        var list = FolderPathList(["/Users/test/Movies"])

        let refused = list.add([movies, URL(filePath: "/Users/test/Movies/"), music, music], as: { $0 })

        #expect(list.paths == ["/Users/test/Movies", "/Users/test/Music"])
        #expect(refused.isEmpty)
    }

    @Test func addsEachFolderSpelledAsItIsGiven() {
        var list = FolderPathList([])

        list.add([URL(filePath: "/Users/test/movies")], as: { _ in movies })

        #expect(list.paths == ["/Users/test/Movies"])
    }

    @Test func leavesOutTheFoldersItDoesNotTake() {
        var list = FolderPathList(["/Users/test/Movies"])

        let refused = list.add([music, movies.appending(path: "Trips")], as: { $0 == music ? $0 : nil })

        #expect(list.paths == ["/Users/test/Movies", "/Users/test/Music"])
        #expect(refused == [movies.appending(path: "Trips")])
    }

    @Test func removesAFolder() {
        var list = FolderPathList(["/Users/test/Movies", "/Users/test/Music"])

        list.remove("/Users/test/Movies")

        #expect(list.paths == ["/Users/test/Music"])
    }
}
