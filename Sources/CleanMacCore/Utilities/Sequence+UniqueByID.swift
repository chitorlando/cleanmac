import Foundation

public extension Sequence where Element: Identifiable {
    /// The elements without repeated ids, keeping the first occurrence of each in its original order.
    func uniquedByID() -> [Element] {
        var seen = Set<Element.ID>()
        return filter { seen.insert($0.id).inserted }
    }
}
