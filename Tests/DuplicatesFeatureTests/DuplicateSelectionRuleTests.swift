import CleanMacCore
import DuplicatesFeature
import Testing

struct DuplicateSelectionRuleTests {
    private typealias Fixtures = DuplicateFixtures
    private typealias Rule = DuplicateSelectionRule

    private let original = Fixtures.file("/Users/test/report.pdf", created: Fixtures.date(1))
    private let download = Fixtures.file("/Users/test/Downloads/report.pdf", created: Fixtures.date(2))
    private let desktop = Fixtures.file("/Users/test/Desktop/report.pdf", created: Fixtures.date(3))
    private var group: DuplicateGroup { Fixtures.group(original, download, desktop) }

    private func selection(_ files: DuplicateFile...) -> ItemSelection {
        var selection = ItemSelection()
        selection.select(files.map(\.item))
        return selection
    }

    // MARK: Never every copy

    @Test func cannotMarkTheLastUnmarkedCopy() {
        var selection = selection(download, desktop)

        #expect(!Rule.canSelect(original, in: group, selection: selection))
        Rule.toggle(original, in: group, selection: &selection)

        #expect(!selection.contains(original.item))
    }

    @Test func marksAndUnmarksCopiesOneByOne() {
        var selection = ItemSelection()

        Rule.toggle(download, in: group, selection: &selection)
        Rule.toggle(original, in: group, selection: &selection)
        #expect(selection == self.selection(download, original))

        Rule.toggle(download, in: group, selection: &selection)
        #expect(selection == self.selection(original))
    }

    @Test func aMarkedCopyCanAlwaysBeUnmarked() {
        let selection = selection(download, desktop)

        #expect(Rule.canSelect(download, in: group, selection: selection))
    }

    @Test func neverRemovesEveryCopyOfAGroup() {
        let removable = Rule.removableItems(in: [group], selection: selection(original, download, desktop))

        #expect(Set(removable) == [download.item, desktop.item])
    }

    @Test func neverRemovesEveryCloneThatCannotBeCounted() {
        let older = Fixtures.file("/a", created: Fixtures.date(1), storage: .uncountedClone(stream: 3))
        let newer = Fixtures.file("/b", created: Fixtures.date(2), storage: .uncountedClone(stream: 3))
        let group = Fixtures.group(older, newer)

        #expect(!Rule.canSelect(newer, in: group, selection: selection(older)))
        #expect(Rule.removableItems(in: [group], selection: selection(older, newer)) == [newer.item])
    }

    // MARK: Select duplicates

    @Test func selectingDuplicatesKeepsTheSuggestedCopy() {
        var selection = selection(original)

        Rule.selectDuplicates(in: [group], selection: &selection)

        #expect(selection == self.selection(download, desktop))
        #expect(Rule.state(of: group, selection: selection) == .all)
    }

    @Test func doesNotSelectClonesOfTheKeptCopy() {
        let keptClone = Fixtures.file("/Users/test/Mail/report.pdf", created: Fixtures.date(4), storage: .clone(stream: 1, count: 2))
        let clonedOriginal = Fixtures.file("/Users/test/report.pdf", created: Fixtures.date(1), storage: .clone(stream: 1, count: 2))
        let group = Fixtures.group(clonedOriginal, download, keptClone)
        var selection = ItemSelection()

        Rule.selectDuplicates(in: [group], selection: &selection)

        #expect(selection == self.selection(download))
        #expect(Rule.state(of: group, selection: selection) == .all)
    }

    @Test func selectsClonesOfEachOtherTogether() {
        let firstClone = Fixtures.file("/Users/test/Desktop/report.pdf", created: Fixtures.date(5), storage: .clone(stream: 2, count: 2))
        let secondClone = Fixtures.file("/Users/test/Mail/report.pdf", created: Fixtures.date(6), storage: .clone(stream: 2, count: 2))
        let group = Fixtures.group(firstClone, original, secondClone)
        var selection = ItemSelection()

        Rule.selectDuplicates(in: [group], selection: &selection)

        #expect(selection == self.selection(firstClone, secondClone))
        #expect(group.freedSize(removing: [firstClone.id, secondClone.id]) == Fixtures.fileSize)
    }

    @Test func keepsClonesThatCannotBeCountedAndSelectsTheCopiesWithTheirOwnData() {
        let firstClone = Fixtures.file("/Users/test/Desktop/report.pdf", created: Fixtures.date(5), storage: .uncountedClone(stream: 2))
        let secondClone = Fixtures.file("/Users/test/Mail/report.pdf", created: Fixtures.date(6), storage: .uncountedClone(stream: 2))
        let group = Fixtures.group(firstClone, original, download, secondClone)
        var selection = ItemSelection()

        Rule.selectDuplicates(in: [group], selection: &selection)

        #expect(selection == self.selection(original, download))
        #expect(Rule.state(of: group, selection: selection) == .all)
        #expect(group.freedSize(removing: [original.id, download.id]) == Fixtures.fileSize * 2)
    }

    @Test func selectingDuplicatesKeepsAFileWithOtherNames() {
        let linked = Fixtures.file("/Users/test/Mail/report.pdf", created: Fixtures.date(9), linkCount: 2)
        let group = Fixtures.group(original, linked, download)
        var selection = ItemSelection()

        Rule.selectDuplicates(in: [group], selection: &selection)

        #expect(selection == self.selection(original, download))
        #expect(group.freedSize(removing: [original.id, download.id]) == Fixtures.fileSize * 2)
    }

    @Test func selectsNothingWhenEveryCopySharesTheSameData() {
        let group = Fixtures.group(
            Fixtures.file("/a", storage: .clone(stream: 3, count: 2)),
            Fixtures.file("/b", storage: .clone(stream: 3, count: 2))
        )
        var selection = ItemSelection()

        Rule.selectDuplicates(in: [group], selection: &selection)

        #expect(selection.isEmpty)
    }

    // MARK: Group state

    @Test func reportsHowMuchOfAGroupIsMarked() {
        #expect(Rule.state(of: group, selection: ItemSelection()) == .none)
        #expect(Rule.state(of: group, selection: selection(desktop)) == .some)
        #expect(Rule.state(of: group, selection: selection(desktop, original)) == .all)
    }

    @Test func aGroupIsFullyMarkedWhenOnlyClonesOfOneCopyAreLeft() {
        let first = Fixtures.file("/a", storage: .clone(stream: 4, count: 2))
        let second = Fixtures.file("/b", storage: .clone(stream: 4, count: 2))
        let group = Fixtures.group(first, second, download)

        #expect(Rule.state(of: group, selection: selection(download)) == .all)
        #expect(Rule.state(of: group, selection: selection(first)) == .some)
    }

    @Test func togglingAGroupMarksItsDuplicatesOrClearsIt() {
        var selection = ItemSelection()

        Rule.toggle(group, selection: &selection)
        #expect(selection == self.selection(download, desktop))

        Rule.toggle(group, selection: &selection)
        #expect(selection.isEmpty)
    }

    @Test func togglingAGroupOfClonesMarksEveryCopyButTheSuggestedOne() {
        let first = Fixtures.file("/a", created: Fixtures.date(2), storage: .clone(stream: 3, count: 3))
        let oldest = Fixtures.file("/b", created: Fixtures.date(1), storage: .clone(stream: 3, count: 3))
        let last = Fixtures.file("/c", created: Fixtures.date(3), storage: .clone(stream: 3, count: 3))
        let group = Fixtures.group(first, oldest, last)
        var selection = ItemSelection()

        Rule.toggle(group, selection: &selection)

        #expect(selection == self.selection(first, last))
        #expect(Rule.state(of: group, selection: selection) == .all)
    }

    @Test func togglingAPartlyMarkedGroupClearsIt() {
        var selection = selection(desktop)

        Rule.toggle(group, selection: &selection)

        #expect(selection.isEmpty)
    }
}
