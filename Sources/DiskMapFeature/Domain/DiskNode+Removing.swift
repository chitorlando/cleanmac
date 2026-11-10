import Foundation

public extension DiskNode {
    /// The map without the items at `urls`, every folder above them smaller by what they took up.
    ///
    /// Lets the map follow a removal without walking the disk again.
    func removing(_ urls: Set<URL>) -> DiskNode {
        guard !urls.isEmpty, !children.isEmpty else { return self }
        let kept = children.filter { !urls.contains($0.url) }.map { $0.removing(urls) }
        return DiskNode(
            url: url,
            kind: kind,
            size: kept.reduce(otherItems?.size ?? 0) { $0 + $1.size },
            fileCount: kept.reduce(otherItems?.fileCount ?? 0) { $0 + $1.fileCount },
            children: kept.sorted(by: DiskNode.isLarger),
            otherItems: otherItems
        )
    }
}
