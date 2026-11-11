import Combine
import Foundation

/// The item of the disk map pointed at with the mouse or the keyboard.
///
/// It moves on every pass of the mouse over the rings or the list and on every arrow key, far
/// more often than anything else on the screen changes. Kept apart from the view model, a move
/// reaches only the views that draw the highlight, instead of every view that shows the map.
@MainActor
public final class DiskMapHighlight: ObservableObject {
    /// Pointing at another slice of the same branch sets the same item again. A published
    /// property redraws every view that observes it on each assignment, even of the value it
    /// already holds, so only a different item is stored.
    public var itemID: DiskNode.ID? {
        get { storedItemID }
        set {
            guard newValue != storedItemID else { return }
            storedItemID = newValue
        }
    }

    @Published private var storedItemID: DiskNode.ID?

    public init() {}
}
