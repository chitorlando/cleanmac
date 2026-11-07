import Foundation
import LargeFilesFeature
import Testing

struct LargeFileFilterTests {
    private typealias Fixtures = LargeFileFixtures

    private let movie = Fixtures.file("Vacaciones.mov", megabytes: 2_000, lastUsed: Fixtures.date(2024, 1, 1))
    private let song = Fixtures.file("Canción.mp3", megabytes: 60, lastUsed: Fixtures.date(2026, 11, 1))
    private let backup = Fixtures.file("backup.zip", megabytes: 300, lastUsed: Fixtures.date(2026, 8, 1))
    private let unknown = Fixtures.file("old.dmg", megabytes: 80, lastUsed: nil)

    private var files: [LargeFile] { [movie, song, backup, unknown] }

    private func names(_ filter: LargeFileFilter) -> [String] {
        filter.apply(to: files, now: Fixtures.now, calendar: Fixtures.calendar).map(\.item.name)
    }

    @Test func letsEverythingThroughByDefault() {
        #expect(names(LargeFileFilter()) == ["Vacaciones.mov", "Canción.mp3", "backup.zip", "old.dmg"])
    }

    @Test func keepsOnlyTheChosenKinds() {
        #expect(names(LargeFileFilter(kinds: [.video, .archive])) == ["Vacaciones.mov", "backup.zip"])
    }

    @Test func keepsOnlyTheChosenAge() {
        #expect(names(LargeFileFilter(ageBucket: .overOneYear)) == ["Vacaciones.mov"])
        #expect(names(LargeFileFilter(ageBucket: .lessThanOneMonth)) == ["Canción.mp3"])
        #expect(names(LargeFileFilter(ageBucket: .oneToSixMonths)) == ["backup.zip"])
    }

    @Test func leavesFilesWithUnknownDateOutOfEveryAge() {
        let everyAge = AgeBucket.allCases.flatMap { names(LargeFileFilter(ageBucket: $0)) }
        #expect(!everyAge.contains("old.dmg"))
    }

    @Test func keepsOnlyTheChosenSize() {
        #expect(names(LargeFileFilter(sizeBucket: .from50MBTo100MB)) == ["Canción.mp3", "old.dmg"])
        #expect(names(LargeFileFilter(sizeBucket: .over1GB)) == ["Vacaciones.mov"])
    }

    @Test(arguments: ["vacaciones", "CANCION", "  canción  ", ".zip"])
    func searchesNamesIgnoringCaseAndAccents(term: String) {
        #expect(names(LargeFileFilter(searchText: term)).count == 1)
    }

    @Test func combinesEveryCondition() {
        let filter = LargeFileFilter(kinds: [.audio, .diskImage], sizeBucket: .from50MBTo100MB, searchText: "old")
        #expect(names(filter) == ["old.dmg"])
    }
}
