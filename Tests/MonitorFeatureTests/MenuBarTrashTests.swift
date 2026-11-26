import CleanMacCore
import Foundation
@testable import MonitorFeature
import Testing

@MainActor
struct MenuBarTrashTests {
    private func makeTrash(_ usages: [TrashUsage], emptier: FakeTrashEmptier = FakeTrashEmptier()) -> (MenuBarTrash, FakeTrashReader) {
        let reader = FakeTrashReader(usages)
        let trash = MenuBarTrash(
            reader: reader,
            service: TrashEmptyingService(emptier: emptier),
            homeBin: MenuBarTrashFixtures.homeBin
        )
        return (trash, reader)
    }

    @Test func knowsNothingUntilTheTrashIsRead() {
        let (trash, reader) = makeTrash([MenuBarTrashFixtures.full])

        #expect(trash.usage == nil)
        #expect(trash.size == nil)
        #expect(trash.canEmpty)
        #expect(reader.reads == 0)
    }

    @Test func readsTheTrashAwayFromTheMainThread() async {
        let (trash, reader) = makeTrash([MenuBarTrashFixtures.full])

        await trash.read()

        #expect(trash.usage == MenuBarTrashFixtures.full)
        #expect(reader.reads == 1)
        #expect(reader.readsOnMainThread == 0)
    }

    @Test func addsUpEveryBin() async {
        let (trash, _) = makeTrash([MenuBarTrashFixtures.full])

        await trash.read()

        #expect(trash.size == 3_500)
    }

    @Test(.timeLimit(.minutes(1)))
    func readsOnceAtATime() async {
        let (trash, reader) = makeTrash([MenuBarTrashFixtures.full])

        trash.startReading()
        trash.startReading()
        while trash.usage == nil {
            try? await Task.sleep(for: .milliseconds(5))
        }

        #expect(reader.reads == 1)
    }

    /// Without Full Disk Access the size is unknown, but Finder can still empty the Trash.
    @Test func canEmptyATrashItCouldNotMeasure() async {
        let (trash, _) = makeTrash([.unreadable])

        await trash.read()

        #expect(trash.size == nil)
        #expect(trash.canEmpty)
    }

    @Test func cannotEmptyATrashKnownToBeEmpty() async {
        let (trash, _) = makeTrash([MenuBarTrashFixtures.empty])
        await trash.read()

        trash.requestEmpty()

        #expect(trash.size == 0)
        #expect(!trash.canEmpty)
        #expect(!trash.isConfirmingEmpty)
    }

    @Test func asksBeforeEmptyingAndEmptiesNothingUntilConfirmed() async {
        let emptier = FakeTrashEmptier()
        let (trash, _) = makeTrash([MenuBarTrashFixtures.full], emptier: emptier)
        await trash.read()

        trash.requestEmpty()
        #expect(trash.isConfirmingEmpty)
        trash.cancelEmpty()

        #expect(!trash.isConfirmingEmpty)
        #expect(emptier.calls == 0)
    }

    @Test func emptiesOnceConfirmedAndReadsTheTrashAgain() async {
        let emptier = FakeTrashEmptier()
        let (trash, reader) = makeTrash([MenuBarTrashFixtures.full, MenuBarTrashFixtures.empty], emptier: emptier)
        await trash.read()
        trash.requestEmpty()

        await trash.empty()

        #expect(emptier.calls == 1)
        #expect(reader.reads == 2)
        #expect(trash.size == 0)
        #expect(!trash.canEmpty)
        #expect(!trash.isConfirmingEmpty)
        #expect(!trash.isEmptying)
        #expect(!trash.emptyingFailed)
    }

    @Test func emptiesATrashItCouldNotMeasure() async {
        let emptier = FakeTrashEmptier()
        let (trash, _) = makeTrash([.unreadable], emptier: emptier)
        await trash.read()
        trash.requestEmpty()

        await trash.empty()

        #expect(emptier.calls == 1)
    }

    @Test func tellsWhenTheTrashCouldNotBeEmptied() async {
        let emptier = FakeTrashEmptier(fails: true)
        let (trash, _) = makeTrash([MenuBarTrashFixtures.full], emptier: emptier)
        await trash.read()
        trash.requestEmpty()

        await trash.empty()

        #expect(trash.emptyingFailed)
        #expect(trash.canEmpty)
        trash.requestEmpty()
        #expect(!trash.emptyingFailed)
    }
}
