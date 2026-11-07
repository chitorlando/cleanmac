import Foundation

/// Confirms which files of the same size have identical contents:
/// first by hashing their first bytes, then by hashing the files that still match in full.
struct ContentMatcher: Sendable {
    static let partialHashLength: Int64 = 64 * 1024

    let hasher: any FileHashing

    /// Groups of identical files among `candidates`. Files that can't be read are left out.
    /// - Parameter onBytesHashed: Called after each file is hashed with the bytes read.
    func duplicates(
        among candidates: [DuplicateCandidate],
        onBytesHashed: (Int64) -> Void
    ) -> [DuplicateGroup] {
        guard candidates.count > 1 else { return [] }
        return split(candidates, upTo: Self.partialHashLength, onBytesHashed: onBytesHashed)
            .flatMap { split($0.members, upTo: nil, onBytesHashed: onBytesHashed) }
            .map(makeGroup)
    }

    private struct Match {
        let hash: FileHash
        var members: [DuplicateCandidate]
    }

    /// Splits candidates by hash, keeping only the hashes shared by two or more files, in first-seen order.
    private func split(
        _ candidates: [DuplicateCandidate],
        upTo limit: Int64?,
        onBytesHashed: (Int64) -> Void
    ) -> [Match] {
        var matches: [Match] = []
        var indexByDigest: [Data: Int] = [:]
        for candidate in candidates {
            guard !Task.isCancelled else { return [] }
            guard let hash = try? hasher.hash(of: candidate.record.url, upTo: limit) else { continue }
            onBytesHashed(hash.bytesRead)
            if let index = indexByDigest[hash.digest] {
                matches[index].members.append(candidate)
            } else {
                indexByDigest[hash.digest] = matches.count
                matches.append(Match(hash: hash, members: [candidate]))
            }
        }
        return matches.filter { $0.members.count > 1 }
    }

    private func makeGroup(_ match: Match) -> DuplicateGroup {
        let size = match.members.first?.record.size ?? 0
        return DuplicateGroup(
            id: "\(match.hash.hexDigest)-\(size)",
            files: match.members.map(\.file),
            fileSize: size
        )
    }
}
