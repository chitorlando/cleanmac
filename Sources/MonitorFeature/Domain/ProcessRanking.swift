/// What the list of top processes is ordered by.
public enum ProcessRanking: CaseIterable, Hashable, Sendable {
    case cpu
    case memory

    /// The `limit` processes that use the most, largest first, by name when equal.
    public func top(_ usages: [ProcessUsage], limit: Int) -> [ProcessUsage] {
        Array(usages.sorted(by: isOrderedBefore).prefix(max(limit, 0)))
    }

    private func isOrderedBefore(_ lhs: ProcessUsage, _ rhs: ProcessUsage) -> Bool {
        switch self {
        case .cpu where lhs.cpu != rhs.cpu:
            return lhs.cpu > rhs.cpu
        case .memory where lhs.memoryBytes != rhs.memoryBytes:
            return lhs.memoryBytes > rhs.memoryBytes
        default:
            return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
        }
    }
}
