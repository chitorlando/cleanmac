import CleanMacCore

extension DuplicateGroup {
    /// The group without the removed copies, or `nil` when fewer than two copies remain.
    func removing(_ removedIDs: Set<CleanableItem.ID>) -> DuplicateGroup? {
        let remaining = files.filter { !removedIDs.contains($0.id) }
        guard remaining.count > 1 else { return nil }
        return DuplicateGroup(id: id, files: remaining, fileSize: fileSize)
    }

    /// The copies to remove, each sized by the space its removal frees, so their sizes add
    /// up to what removing them all really frees: the last copy of each physical copy removed
    /// whole carries its data, and every other copy counts as zero.
    func itemsToRemove(_ removedIDs: Set<CleanableItem.ID>) -> [CleanableItem] {
        physicalCopies.flatMap { copy -> [CleanableItem] in
            let removed = copy.files.filter { removedIDs.contains($0.id) }
            let freedSize = removed.count == copy.files.count ? copy.freeableSize : 0
            return removed.enumerated().map { index, file in
                CleanableItem(url: file.item.url, size: index == removed.count - 1 ? freedSize : 0)
            }
        }
    }
}
