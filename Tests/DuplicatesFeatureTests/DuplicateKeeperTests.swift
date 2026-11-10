import DuplicatesFeature
import Testing

struct DuplicateKeeperTests {
    private typealias Fixtures = DuplicateFixtures

    @Test func keepsTheOldestCopy() {
        let oldest = Fixtures.file("/Users/test/Downloads/Archive/photo.jpg", created: Fixtures.date(1))
        let group = Fixtures.group(
            Fixtures.file("/Users/test/photo.jpg", created: Fixtures.date(5)),
            oldest,
            Fixtures.file("/Users/test/Desktop/photo.jpg", created: Fixtures.date(3))
        )

        #expect(DuplicateKeeper.keeper(in: group) == oldest)
    }

    @Test func keepsTheShortestPathWhenCreatedAtTheSameTime() {
        let shortest = Fixtures.file("/Users/test/a.jpg")
        let group = Fixtures.group(
            Fixtures.file("/Users/test/Pictures/a.jpg"),
            shortest,
            Fixtures.file("/Users/test/Desktop/a.jpg")
        )

        #expect(DuplicateKeeper.keeper(in: group) == shortest)
    }

    @Test func breaksTiesBetweenPathsOfTheSameLengthAlphabetically() {
        let first = Fixtures.file("/b/a.jpg")
        let group = Fixtures.group(Fixtures.file("/c/a.jpg"), first)

        #expect(DuplicateKeeper.keeper(in: group) == first)
    }

    @Test func prefersCopiesWithAKnownCreationDate() {
        let dated = Fixtures.file("/Users/test/Some/Long/Folder/a.jpg", created: Fixtures.date(9))
        let group = Fixtures.group(Fixtures.file("/a.jpg", created: nil), dated)

        #expect(DuplicateKeeper.keeper(in: group) == dated)
    }

    @Test func keepsACopyWhoseRemovalWouldFreeNothing() {
        // The newer copy is a clone of a file outside the group: removing it frees nothing,
        // so keeping it and removing the older copy is what frees space.
        let sharedOutside = Fixtures.file("/Users/test/Exports/a.jpg", created: Fixtures.date(9), storage: .clone(stream: 7, count: 2))
        let group = Fixtures.group(Fixtures.file("/Users/test/a.jpg", created: Fixtures.date(1)), sharedOutside)

        #expect(DuplicateKeeper.keeper(in: group) == sharedOutside)
    }

    @Test func keepsClonesThatCannotBeCountedBeforeACopyWithItsOwnData() {
        // Nothing says removing these clones would free their data, so the older copy goes instead.
        let oldClone = Fixtures.file("/Users/test/Desktop/a.jpg", created: Fixtures.date(2), storage: .uncountedClone(stream: 7))
        let group = Fixtures.group(
            Fixtures.file("/Users/test/a.jpg", created: Fixtures.date(1)),
            Fixtures.file("/Users/test/b/a.jpg", created: Fixtures.date(3), storage: .uncountedClone(stream: 7)),
            oldClone
        )

        #expect(DuplicateKeeper.keeper(in: group) == oldClone)
    }

    @Test func keepsTheOldestCopyAmongClonesOfEachOther() {
        let oldClone = Fixtures.file("/Users/test/Desktop/a.jpg", created: Fixtures.date(2), storage: .clone(stream: 7, count: 2))
        let group = Fixtures.group(
            Fixtures.file("/Users/test/a.jpg", created: Fixtures.date(4)),
            Fixtures.file("/Users/test/b/a.jpg", created: Fixtures.date(3), storage: .clone(stream: 7, count: 2)),
            oldClone
        )

        #expect(DuplicateKeeper.keeper(in: group) == oldClone)
    }
}
