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
