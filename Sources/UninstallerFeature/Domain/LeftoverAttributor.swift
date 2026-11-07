/// Assigns each Library item to the installed app it most specifically belongs to.
///
/// A less specific match never takes files from another installed app: with Vivaldi
/// ("com.vivaldi.Vivaldi") and one of its web apps ("com.vivaldi.Vivaldi.app.<id>"),
/// the web app's files go to the web app only. Ties, such as two copies of the same
/// app, give the item to every tied app.
public struct LeftoverAttributor: Sendable {
    public init() {}

    public func attribute(
        _ candidates: [LeftoverCandidate],
        to apps: [AppBundleInfo]
    ) -> [AppBundleInfo.ID: [LeftoverCandidate]] {
        var result: [AppBundleInfo.ID: [LeftoverCandidate]] = [:]
        for candidate in candidates {
            for owner in owners(of: candidate, among: apps) {
                result[owner.id, default: []].append(candidate)
            }
        }
        return result
    }

    private func owners(of candidate: LeftoverCandidate, among apps: [AppBundleInfo]) -> [AppBundleInfo] {
        let fileName = candidate.url.lastPathComponent
        let matches = apps.compactMap { app in
            LeftoverMatcher
                .strength(of: fileName, for: app, rules: candidate.location.rules)
                .map { (app: app, strength: $0) }
        }
        guard let best = matches.map(\.strength).max() else { return [] }
        return matches.filter { $0.strength == best }.map(\.app)
    }
}
