import Foundation

public extension FallbackItemRemover {
    /// Moves items to the Trash directly and asks Finder to do it when that needs permission,
    /// for example with apps owned by the system.
    static var trashWithFinderFallback: FallbackItemRemover {
        FallbackItemRemover(primary: TrashItemRemover(), fallback: FinderTrashRemover())
    }
}
