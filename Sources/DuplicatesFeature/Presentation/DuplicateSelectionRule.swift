import CleanMacCore

/// Selection of copies that always leaves at least one copy of every group unmarked.
///
/// "Select duplicates" keeps the copy `DuplicateKeeper` suggests together with its clones,
/// which share its data and would free nothing, and marks every other copy. Clones of each
/// other are marked together, since only removing all of them frees their space.
public enum DuplicateSelectionRule {
    /// A copy can be marked unless every other copy of its group is already marked.
    public static func canSelect(_ file: DuplicateFile, in group: DuplicateGroup, selection: ItemSelection) -> Bool {
        selection.contains(file.item)
            || group.files.contains { $0.id != file.id && !selection.contains($0.item) }
    }

    public static func toggle(_ file: DuplicateFile, in group: DuplicateGroup, selection: inout ItemSelection) {
        guard canSelect(file, in: group, selection: selection) else { return }
        selection.toggle(file.item)
    }

    /// Marks every copy outside the physical copy of the suggested keeper, in each group.
    public static func selectDuplicates(in groups: [DuplicateGroup], selection: inout ItemSelection) {
        for group in groups {
            guard
                let keeper = DuplicateKeeper.keeper(in: group),
                let kept = group.physicalCopy(containing: keeper)
            else { continue }
            let keptIDs = Set(kept.files.map(\.id))
            selection.deselect(kept.files.map(\.item))
            selection.select(group.files.filter { !keptIDs.contains($0.id) }.map(\.item))
        }
    }

    /// `.all` once the unmarked copies keep a single physical copy, the most "Select duplicates" marks.
    public static func state(of group: DuplicateGroup, selection: ItemSelection) -> ItemSelection.State {
        guard group.items.contains(where: selection.contains) else { return .none }
        let keptCopies = group.physicalCopies.count { copy in
            copy.files.contains { !selection.contains($0.item) }
        }
        return keptCopies <= 1 ? .all : .some
    }

    /// Clears a group with any marked copy; otherwise marks its duplicates.
    ///
    /// A group made only of clones frees no space, so "Select duplicates" leaves it alone,
    /// but marking it by hand marks every copy but the suggested one, to tidy up folders.
    public static func toggle(_ group: DuplicateGroup, selection: inout ItemSelection) {
        guard state(of: group, selection: selection) == .none else {
            selection.deselect(group.items)
            return
        }
        if group.isMadeOfClones, let keeper = DuplicateKeeper.keeper(in: group) {
            selection.select(group.files.filter { $0.id != keeper.id }.map(\.item))
        } else {
            selectDuplicates(in: [group], selection: &selection)
        }
    }

    /// The marked copies to remove. As a last safeguard, a group whose copies are all
    /// marked keeps its suggested copy.
    public static func removableItems(in groups: [DuplicateGroup], selection: ItemSelection) -> [CleanableItem] {
        groups.flatMap { group -> [CleanableItem] in
            let marked = group.files.filter { selection.contains($0.item) }
            guard marked.count == group.files.count, let keeper = DuplicateKeeper.keeper(in: group) else {
                return marked.map(\.item)
            }
            return marked.filter { $0.id != keeper.id }.map(\.item)
        }
    }
}
