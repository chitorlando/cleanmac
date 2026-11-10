import CleanMacCore
import DiskMapFeature
import Foundation
import Testing

struct DiskTreeBuilderTests {
    private let root = URL(filePath: "/Users/test")

    private func record(_ path: String, _ size: Int64, isPackage: Bool = false) -> FileRecord {
        FileRecord(url: root.appending(path: path), size: size, accessDate: nil, modificationDate: nil, isPackage: isPackage)
    }

    /// Without grouping every item is shown, which isolates the sums and the order.
    private func map(_ records: [FileRecord], grouping: SmallItemGrouping = .off) -> DiskNode {
        let builder = DiskTreeBuilder(root: root, grouping: grouping)
        records.forEach(builder.add)
        return builder.build()
    }

    private func child(_ name: String, of node: DiskNode) throws -> DiskNode {
        try #require(node.children.first { $0.name == name })
    }

    private var library: [FileRecord] {
        [
            record("Movies/Trips/beach.mov", 400),
            record("Movies/clip.mov", 100),
            record("Documents/report.pdf", 50)
        ]
    }

    // MARK: Sizes and order

    @Test func addsUpTheSizeAndFilesOfEveryFolder() throws {
        let map = map(library)
        let movies = try child("Movies", of: map)

        #expect(map.size == 550)
        #expect(map.fileCount == 3)
        #expect(movies.size == 500)
        #expect(movies.fileCount == 2)
        #expect(try child("Trips", of: movies).size == 400)
    }

    @Test func listsTheLargestItemsFirst() throws {
        let map = map(library)

        #expect(map.children.map(\.name) == ["Movies", "Documents"])
        #expect(try child("Movies", of: map).children.map(\.name) == ["Trips", "clip.mov"])
    }

    @Test func ordersItemsOfTheSameSizeByName() {
        let map = map([record("b.bin", 10), record("c.bin", 20), record("a.bin", 10)])

        #expect(map.children.map(\.name) == ["c.bin", "a.bin", "b.bin"])
    }

    @Test func describesFoldersFilesAndPackages() throws {
        let map = map(library + [record("Applications/Tool.app", 900, isPackage: true)])
        let tool = try child("Tool.app", of: child("Applications", of: map))

        #expect(map.kind == .folder)
        #expect(try child("Movies", of: map).kind == .folder)
        #expect(try child("report.pdf", of: child("Documents", of: map)).kind == .file)
        #expect(tool.kind == .package)
        #expect(tool.fileCount == 1)
        #expect(tool.children.isEmpty)
    }

    @Test func givesFoldersTheirURLInsideTheRoot() throws {
        let movies = try child("Movies", of: map(library))

        #expect(movies.url.path(percentEncoded: false) == "/Users/test/Movies/")
        #expect(try child("clip.mov", of: movies).url == root.appending(path: "Movies/clip.mov"))
    }

    // MARK: Small items

    @Test func countsSmallItemsTogetherAsOther() throws {
        let map = map(
            [
                record("big.bin", 10_000),
                record("tiny.txt", 50),
                record("note.txt", 50),
                record("Small/a.txt", 30),
                record("Small/b.txt", 20)
            ],
            grouping: SmallItemGrouping(minimumShare: 0.01)
        )

        #expect(map.size == 10_150)
        #expect(map.children.map(\.name) == ["big.bin"])
        #expect(map.otherItems == OtherItems(itemCount: 3, size: 150, fileCount: 4))
    }

    @Test func showsALoneSmallItemAsItself() {
        let map = map([record("big.bin", 10_000), record("tiny.txt", 50)], grouping: SmallItemGrouping(minimumShare: 0.01))

        #expect(map.children.map(\.name) == ["big.bin", "tiny.txt"])
        #expect(map.otherItems == nil)
    }

    @Test func alwaysShowsItemsOfTheMinimumSize() {
        let map = map(
            [
                record("disk.img", 5_000_000_000),
                record("video.mov", 20_000_000),
                record("photo.jpg", 2_000_000),
                record("song.mp3", 1_000_000)
            ],
            grouping: SmallItemGrouping()
        )

        #expect(map.children.map(\.name) == ["disk.img", "video.mov"])
        #expect(map.otherItems == OtherItems(itemCount: 2, size: 3_000_000, fileCount: 2))
    }

    @Test func countsEmptyItemsTogether() {
        let map = map([record("a.lock", 0), record("b.lock", 0), record("c.lock", 0)], grouping: SmallItemGrouping())

        #expect(map.children.isEmpty)
        #expect(map.otherItems == OtherItems(itemCount: 3, size: 0, fileCount: 3))
    }

    @Test func groupsByTheShareOfEachFolder() throws {
        let map = map(
            [
                record("Movies/film.mov", 100_000),
                record("Notes/a.txt", 60),
                record("Notes/b.txt", 40),
                record("Notes/c.txt", 10),
                record("Notes/d.txt", 5)
            ],
            grouping: SmallItemGrouping(minimumShare: 0.1)
        )
        let notes = try child("Notes", of: map)

        #expect(map.children.map(\.name) == ["Movies", "Notes"])
        #expect(notes.children.map(\.name) == ["a.txt", "b.txt"])
        #expect(notes.otherItems == OtherItems(itemCount: 2, size: 15, fileCount: 2))
    }

    @Test func keepsEveryFolderAsLargeAsItsItemsAndOther() {
        let map = map(
            library + (1...40).map { record("Documents/Old/note\($0).txt", Int64($0)) },
            grouping: SmallItemGrouping(minimumShare: 0.05)
        )

        func check(_ node: DiskNode) {
            guard node.kind == .folder else { return }
            let shown = node.children.reduce(Int64(0)) { $0 + $1.size }
            #expect(node.size == shown + (node.otherItems?.size ?? 0), "\(node.name)")
            node.children.forEach(check)
        }
        check(map)
    }

    @Test func buildsTheSameMapInAnyOrder() {
        let records = [
            record("big.bin", 10_000),
            record("tiny.txt", 50),
            record("note.txt", 50),
            record("Movies/film.mov", 5_000),
            record("Movies/trailer.mov", 20),
            record("Movies/poster.jpg", 10)
        ]

        let inOrder = map(records, grouping: SmallItemGrouping(minimumShare: 0.01))

        #expect(map(records.reversed(), grouping: SmallItemGrouping(minimumShare: 0.01)) == inOrder)
        #expect(map(records.sorted { $0.size < $1.size }, grouping: SmallItemGrouping(minimumShare: 0.01)) == inOrder)
    }

    // MARK: Edge cases

    @Test func mapsAnEmptyFolder() {
        #expect(map([]) == DiskNode(url: root, kind: .folder, size: 0, fileCount: 0))
    }

    @Test func findsFilesUnderTheRealPathOfARootBehindASymbolicLink() throws {
        let folder = try TemporaryFolder()
        let realRoot = try #require(try folder.root.resourceValues(forKeys: [.canonicalPathKey]).canonicalPath)
        try #require(realRoot != folder.root.path(percentEncoded: false), "The temporary folder is expected under /var, a link to /private/var.")
        let builder = DiskTreeBuilder(root: folder.root)

        builder.add(FileRecord(url: URL(filePath: realRoot).appending(path: "Movies/clip.mov"), size: 10, accessDate: nil, modificationDate: nil))

        let movies = try child("Movies", of: builder.build())
        #expect(movies.size == 10)
        #expect(movies.url == folder.root.appending(path: "Movies", directoryHint: .isDirectory))
    }

    @Test func ignoresFilesOutsideTheRoot() {
        let outside = FileRecord(url: URL(filePath: "/Users/other/big.bin"), size: 10, accessDate: nil, modificationDate: nil)
        let sibling = FileRecord(url: URL(filePath: "/Users/tester/big.bin"), size: 10, accessDate: nil, modificationDate: nil)

        #expect(map([outside, sibling]).size == 0)
    }
}
