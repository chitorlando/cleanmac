import DiskMapFeature
import Foundation
import Testing

struct SunburstLayoutTests {
    private let root = URL(filePath: "/Users/test")

    private func file(_ path: String, _ size: Int64) -> DiskNode {
        DiskNode(url: root.appending(path: path), kind: .file, size: size, fileCount: 1)
    }

    private func folder(_ path: String, _ children: [DiskNode], other: OtherItems? = nil) -> DiskNode {
        let size = children.reduce(other?.size ?? 0) { $0 + $1.size }
        let files = children.reduce(other?.fileCount ?? 0) { $0 + $1.fileCount }
        return DiskNode(url: root.appending(path: path), kind: .folder, size: size, fileCount: files, children: children, otherItems: other)
    }

    private func angles(_ segments: [RingSegment]) -> [[Double]] {
        segments.map { [$0.startDegrees.rounded(), $0.endDegrees.rounded()] }
    }

    @Test func sizesSlicesByTheirShareOfTheFolder() {
        let home = folder("", [file("a", 200), file("b", 100), file("c", 100)])

        let segments = SunburstLayout().segments(around: home)

        #expect(segments.map(\.node?.name) == ["a", "b", "c"])
        #expect(angles(segments) == [[0, 180], [180, 270], [270, 360]])
        #expect(segments.allSatisfy { $0.ring == 0 })
    }

    @Test func placesTheItemsOfAFolderOutsideItsSlice() {
        let movies = folder("Movies", [file("Movies/a.mov", 150), file("Movies/b.mov", 50)])
        let home = folder("", [movies, file("notes.txt", 200)])

        let outer = SunburstLayout().segments(around: home).filter { $0.ring == 1 }

        #expect(outer.map(\.node?.name) == ["a.mov", "b.mov"])
        #expect(angles(outer) == [[0, 135], [135, 180]])
    }

    @Test func drawsThreeRingsAtMost() {
        let deep = folder("a", [folder("a/b", [folder("a/b/c", [folder("a/b/c/d", [file("a/b/c/d/e", 10)])])])])

        let segments = SunburstLayout().segments(around: folder("", [deep]))

        #expect(segments.map(\.node?.name) == ["a", "b", "c"])
        #expect(segments.map(\.ring) == [0, 1, 2])
    }

    @Test func endsEachFolderWithItsSmallItemsInGray() throws {
        let home = folder("", [file("big", 300)], other: OtherItems(itemCount: 4, size: 100, fileCount: 4))

        let segments = SunburstLayout().segments(around: home)
        let last = try #require(segments.last)

        #expect(last.content == .other(folder: root.appending(path: ""), itemCount: 4, size: 100))
        #expect(angles([last]) == [[270, 360]])
    }

    @Test func addsSlicesTooNarrowToDrawToTheSmallItems() throws {
        let home = folder(
            "",
            [file("big", 9_000), file("tiny", 30), file("speck", 20)],
            other: OtherItems(itemCount: 2, size: 50, fileCount: 2)
        )

        let segments = SunburstLayout(minimumDegrees: 2).segments(around: home)

        #expect(segments.map(\.node?.name) == ["big", nil])
        let other = try #require(segments.last)
        #expect(other.size == 100)
        guard case .other(_, let itemCount, _) = other.content else {
            Issue.record("Expected the small items last")
            return
        }
        #expect(itemCount == 4)
        #expect(abs(other.endDegrees - 360) < 0.001)
    }

    @Test func colorsWholeBranchesAlike() {
        let movies = folder("Movies", [file("Movies/a.mov", 150), file("Movies/b.mov", 50)])
        let music = folder("Music", [file("Music/song.mp3", 100)])

        let segments = SunburstLayout().segments(around: folder("", [movies, music]))

        #expect(segments.map(\.branch) == [0, 1, 0, 0, 1])
    }

    @Test func drawsNothingForAnEmptyFolder() {
        #expect(SunburstLayout().segments(around: folder("", [])).isEmpty)
    }

    @Test func identifiesSlicesByWhatTheyStandFor() {
        let home = folder("", [file("big", 300)], other: OtherItems(itemCount: 2, size: 100, fileCount: 2))

        let ids = SunburstLayout().segments(around: home).map(\.id)

        #expect(ids == ["item:/Users/test/big", "other:/Users/test"])
    }
}
