import Foundation

/// The age ranges of a moment, good for a short while after it.
///
/// The ranges move with the clock, so nothing worked out from them can be kept forever,
/// and working it out again on every read is what made the screen slow. A file changes
/// range a month, six months or a year after its last use, and at those ages the list
/// tells when in months, so ranges up to a minute old still place every file where
/// the user expects it.
struct AgeBucketSnapshot: Sendable {
    /// How long the ranges are used before they're worked out again.
    static let lifetime: TimeInterval = 60

    let boundaries: AgeBucketBoundaries
    private let date: Date

    init(now: Date, calendar: Calendar) {
        boundaries = AgeBucketBoundaries(now: now, calendar: calendar)
        date = now
    }

    /// Whether the ranges still stand at `now`. A clock set back makes them outdated too.
    func isCurrent(at now: Date) -> Bool {
        abs(now.timeIntervalSince(date)) < Self.lifetime
    }
}
