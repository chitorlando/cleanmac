import DuplicatesFeature
import Testing

struct DuplicateListQueryTests {
    private typealias Fixtures = DuplicateFixtures

    /// Recovers one copy's worth of space.
    private let report = Fixtures.group(Fixtures.file("/Users/test/Report.pdf"), Fixtures.file("/Users/test/Documents/Report.pdf"))
    /// Recovers two copies' worth of space.
    private let video = Fixtures.group(
        Fixtures.file("/Users/test/Movies/video.mov"),
        Fixtures.file("/Users/test/Desktop/video.mov"),
        Fixtures.file("/Users/test/Año 2024/vídeo.mov")
    )
    /// Recovers nothing: both copies share the same data.
    private let archive = Fixtures.group(
        Fixtures.file("/Users/test/archive.zip", storage: .clone(stream: 1, count: 2)),
        Fixtures.file("/Users/test/Backups/archive.zip", storage: .clone(stream: 1, count: 2))
    )
    private var groups: [DuplicateGroup] { [archive, report, video] }

    @Test func sortsByRecoverableSpaceByDefault() {
        #expect(DuplicateListQuery().apply(to: groups) == [video, report, archive])
    }

    @Test func sortsByNameAsTheFinderDoes() {
        let query = DuplicateListQuery(sortOrder: .name)

        #expect(query.apply(to: groups) == [archive, report, video])
    }

    @Test func breaksTiesInSpaceByName() {
        let other = Fixtures.group(Fixtures.file("/Users/test/notes.pdf"), Fixtures.file("/Users/test/Old/notes.pdf"))

        #expect(DuplicateListQuery().apply(to: [report, other]) == [other, report])
    }

    @Test func searchesThePathOfEveryCopyIgnoringCaseAndAccents() {
        #expect(DuplicateListQuery(searchText: "REPORT").apply(to: groups) == [report])
        #expect(DuplicateListQuery(searchText: "backups").apply(to: groups) == [archive])
        #expect(DuplicateListQuery(searchText: "ano 2024").apply(to: groups) == [video])
    }

    @Test func ignoresBlankSearches() {
        #expect(DuplicateListQuery(searchText: "  ").apply(to: groups).count == 3)
    }

    @Test func findsNothingWhenNoPathMatches() {
        #expect(DuplicateListQuery(searchText: "Photoshop").apply(to: groups).isEmpty)
    }
}
