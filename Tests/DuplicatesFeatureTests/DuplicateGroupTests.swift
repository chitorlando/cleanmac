import CleanMacCore
import DuplicatesFeature
import Foundation
import Testing

struct DuplicateGroupTests {
    private typealias Fixtures = DuplicateFixtures
    private let size = DuplicateFixtures.fileSize

    // MARK: Physical copies

    @Test func everyCopyWithItsOwnDataIsAPhysicalCopy() {
        let group = Fixtures.group(Fixtures.file("/a"), Fixtures.file("/b"), Fixtures.file("/c"))

        #expect(group.physicalCopies.map(\.files) == group.files.map { [$0] })
        #expect(group.physicalCopies.allSatisfy { $0.freeableSize == size })
        #expect(group.recoverableSize == size * 2)
    }

    @Test func clonesOfEachOtherAreOnePhysicalCopy() {
        let first = Fixtures.file("/first", storage: .clone(stream: 7, count: 2))
        let own = Fixtures.file("/own")
        let second = Fixtures.file("/second", storage: .clone(stream: 7, count: 2))
        let group = Fixtures.group(first, own, second)

        #expect(group.physicalCopies.map(\.files) == [[first, second], [own]])
        #expect(group.physicalCopies.map(\.freeableSize) == [size, size])
        #expect(group.recoverableSize == size)
    }

    @Test func recoversNothingWhenEveryCopyIsAClone() {
        let group = Fixtures.group(
            Fixtures.file("/a", storage: .clone(stream: 7, count: 2)),
            Fixtures.file("/b", storage: .clone(stream: 7, count: 2))
        )

        #expect(group.physicalCopies.count == 1)
        #expect(group.recoverableSize == 0)
    }

    @Test func clonesOnDifferentVolumesAreDifferentPhysicalCopies() {
        let item = { (path: String) in CleanableItem(url: URL(filePath: path), size: self.size) }
        let info = { (device: Int64) in
            CloneInfo(streamID: CloneInfo.StreamID(device: device, cloneID: 7), cloneCount: 1, mayShareSomeData: false)
        }
        let group = Fixtures.group(
            DuplicateFile(item: item("/a"), creationDate: nil, cloneInfo: info(1)),
            DuplicateFile(item: item("/Volumes/Backup/a"), creationDate: nil, cloneInfo: info(2))
        )

        #expect(group.physicalCopies.count == 2)
        #expect(group.recoverableSize == size)
    }

    // MARK: Space that can't be counted

    @Test func doesNotCountDataSharedWithFilesOutsideTheGroup() {
        // A third clone lives elsewhere, such as in the Trash, so removing both copies frees nothing.
        let clones = Fixtures.group(
            Fixtures.file("/a", storage: .clone(stream: 7, count: 3)),
            Fixtures.file("/b", storage: .clone(stream: 7, count: 3))
        )

        #expect(clones.physicalCopies.map(\.freeableSize) == [0])
        #expect(clones.recoverableSize == 0)
    }

    @Test func keepsTheCopyThatFreesNothingWhenCountingRecoverableSpace() {
        let group = Fixtures.group(
            Fixtures.file("/own"),
            Fixtures.file("/clone", storage: .clone(stream: 7, count: 2)),
            Fixtures.file("/other")
        )

        #expect(group.physicalCopies.map(\.freeableSize) == [size, 0, size])
        #expect(group.recoverableSize == size * 2)
    }

    @Test func doesNotCountCopiesThatMayShareSomeData() {
        let group = Fixtures.group(
            Fixtures.file("/a", storage: .partlyShared),
            Fixtures.file("/b", storage: .partlyShared),
            Fixtures.file("/c")
        )

        #expect(group.physicalCopies.map(\.freeableSize) == [0, 0, size])
        #expect(group.recoverableSize == size)
    }

    @Test func doesNotCountClonesThatCannotBeCounted() {
        // More clones may live outside the group, so removing both frees nothing for certain.
        let first = Fixtures.file("/first", storage: .uncountedClone(stream: 7))
        let second = Fixtures.file("/second", storage: .uncountedClone(stream: 7))
        let own = Fixtures.file("/own")
        let group = Fixtures.group(first, own, second)

        #expect(group.physicalCopies.map(\.files) == [[first, second], [own]])
        #expect(group.physicalCopies.map(\.freeableSize) == [0, size])
        #expect(group.recoverableSize == size)
        #expect(group.freedSize(removing: [first.id, second.id]) == 0)
        #expect(group.freedSize(removing: [own.id]) == size)
    }

    @Test func recoversNothingFromClonesThatCannotBeCounted() {
        let clones = Fixtures.group(
            Fixtures.file("/a", storage: .uncountedClone(stream: 7)),
            Fixtures.file("/b", storage: .uncountedClone(stream: 7))
        )
        let families = Fixtures.group(
            Fixtures.file("/a", storage: .uncountedClone(stream: 7)),
            Fixtures.file("/b", storage: .uncountedClone(stream: 7)),
            Fixtures.file("/c", storage: .uncountedClone(stream: 8)),
            Fixtures.file("/d", storage: .uncountedClone(stream: 8))
        )

        #expect(clones.isMadeOfClones)
        #expect(clones.recoverableSize == 0)
        #expect(families.physicalCopies.count == 2)
        #expect(!families.isMadeOfClones)
        #expect(families.recoverableSize == 0)
    }

    @Test func doesNotCountCopiesWhoseVolumeCouldNotTell() {
        let group = Fixtures.group(
            Fixtures.file("/a", storage: .unknown),
            Fixtures.file("/b", storage: .unknown)
        )

        #expect(group.physicalCopies.count == 2)
        #expect(group.recoverableSize == 0)
    }

    // MARK: Freed space

    @Test func freesAClonesDataOnlyWhenAllOfItsCopiesAreRemoved() {
        let first = Fixtures.file("/first", storage: .clone(stream: 7, count: 2))
        let second = Fixtures.file("/second", storage: .clone(stream: 7, count: 2))
        let own = Fixtures.file("/own")
        let group = Fixtures.group(own, first, second)

        #expect(group.freedSize(removing: [first.id]) == 0)
        #expect(group.freedSize(removing: [first.id, second.id]) == size)
        #expect(group.freedSize(removing: [own.id, first.id]) == size)
        #expect(group.freedSize(removing: []) == 0)
    }

    @Test func findsThePhysicalCopyOfAFile() {
        let first = Fixtures.file("/first", storage: .clone(stream: 7, count: 2))
        let second = Fixtures.file("/second", storage: .clone(stream: 7, count: 2))
        let group = Fixtures.group(Fixtures.file("/own"), first, second)

        #expect(group.physicalCopy(containing: second)?.files == [first, second])
        #expect(group.physicalCopy(containing: Fixtures.file("/elsewhere")) == nil)
    }

    @Test func aGroupIsMadeOfClonesWhenEveryCopySharesTheSameData() {
        let clones = Fixtures.group(
            Fixtures.file("/a", storage: .clone(stream: 7, count: 2)),
            Fixtures.file("/b", storage: .clone(stream: 7, count: 2))
        )
        let mixed = Fixtures.group(Fixtures.file("/a", storage: .clone(stream: 7, count: 2)), Fixtures.file("/c"))
        let unknown = Fixtures.group(Fixtures.file("/a", storage: .unknown), Fixtures.file("/b", storage: .unknown))

        #expect(clones.isMadeOfClones)
        #expect(!mixed.isMadeOfClones)
        // Nothing is counted for these either, but nothing says they are clones.
        #expect(!unknown.isMadeOfClones)
        #expect(unknown.recoverableSize == 0)
    }

    @Test func aCopyIsACloneWhenAnotherFileSharesAllOfItsData() {
        #expect(Fixtures.file("/a", storage: .clone(stream: 7, count: 2)).isClone)
        #expect(!Fixtures.file("/b").isClone)
        #expect(!Fixtures.file("/c", storage: .partlyShared).isClone)
        #expect(!Fixtures.file("/d", storage: .unknown).isClone)
    }

    @Test func aCopyWhoseClonesCannotBeCountedIsNotKnownToBeAClone() {
        #expect(!Fixtures.file("/a", storage: .uncountedClone(stream: 7)).isClone)
    }

    @Test func tellsClonesThatCannotBeCountedByTheCopiesOnTheirDataStream() {
        let first = Fixtures.file("/first", storage: .uncountedClone(stream: 7))
        let second = Fixtures.file("/second", storage: .uncountedClone(stream: 7))
        let alone = Fixtures.file("/alone", storage: .uncountedClone(stream: 8))
        let own = Fixtures.file("/own")
        let group = Fixtures.group(first, alone, own, second)

        #expect(group.isClone(first))
        #expect(group.isClone(second))
        // It may be a clone of a file outside the group, but nothing says so.
        #expect(!group.isClone(alone))
        #expect(!group.isClone(own))
    }

    @Test func tellsCountedClonesWhoseOtherFilesAreOutsideTheGroup() {
        let sharedOutside = Fixtures.file("/a", storage: .clone(stream: 7, count: 2))
        let group = Fixtures.group(sharedOutside, Fixtures.file("/b"), Fixtures.file("/c", storage: .partlyShared))

        #expect(group.isClone(sharedOutside))
        #expect(group.files.dropFirst().allSatisfy { !group.isClone($0) })
    }
}
