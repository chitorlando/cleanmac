import CleanMacCore
import DiskMapFeature
import Foundation
import Testing

struct DiskNodeTests {
    private let url = URL(filePath: "/Users/test/Movies/trip.mov")

    @Test func isNamedAndIdentifiedByItsURL() {
        let node = DiskNode(url: url, kind: .file, size: 10, fileCount: 1)

        #expect(node.name == "trip.mov")
        #expect(node.id == url)
    }

    @Test func countsTheFoldersInsideThatCouldNotBeRead() {
        let home = URL(filePath: "/Users/test")
        let mail = DiskNode(url: home.appending(path: "Library/Mail"), kind: .folder, size: 0, fileCount: 0, isUnreadable: true)
        let library = DiskNode(url: home.appending(path: "Library"), kind: .folder, size: 0, fileCount: 0, children: [mail])
        let movie = DiskNode(url: url, kind: .file, size: 10, fileCount: 1)

        let map = DiskNode(url: home, kind: .folder, size: 10, fileCount: 1, children: [movie, library])

        #expect(mail.unreadableFolderCount == 1)
        #expect(library.unreadableFolderCount == 1)
        #expect(!library.isUnreadable)
        #expect(map.unreadableFolderCount == 1)
        #expect(movie.unreadableFolderCount == 0)
    }

    @Test func describesAWalkedFile() {
        let node = DiskNode(record: FileRecord(url: url, size: 4_096, accessDate: nil, modificationDate: nil))

        #expect(node == DiskNode(url: url, kind: .file, size: 4_096, fileCount: 1))
    }

    @Test func describesAWalkedPackageAsOneFile() {
        let app = URL(filePath: "/Users/test/Applications/Tool.app")
        let record = FileRecord(url: app, size: 90_000, accessDate: nil, modificationDate: nil, isPackage: true)

        let node = DiskNode(record: record)

        #expect(node.kind == .package)
        #expect(node.fileCount == 1)
        #expect(node.children.isEmpty)
    }
}
