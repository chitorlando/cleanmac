import Foundation

/// The dates that separate the age buckets on a given day.
///
/// Working them out takes calendar arithmetic, slow next to everything else a filter does
/// with a file, and they're the same for every file. A pass over the files works them out
/// once, so filtering and counting thousands of files stays within a frame.
struct AgeBucketBoundaries: Sendable {
    private let oneMonthAgo: Date
    private let sixMonthsAgo: Date
    private let oneYearAgo: Date

    init(now: Date, calendar: Calendar) {
        func monthsAgo(_ months: Int) -> Date {
            calendar.date(byAdding: .month, value: -months, to: now) ?? now
        }
        oneMonthAgo = monthsAgo(1)
        sixMonthsAgo = monthsAgo(6)
        oneYearAgo = monthsAgo(12)
    }

    /// The bucket of a file last used on `date`, or `nil` when the date is unknown.
    func bucket(forLastAccessDate date: Date?) -> AgeBucket? {
        guard let date else { return nil }
        if date > oneMonthAgo { return .lessThanOneMonth }
        if date > sixMonthsAgo { return .oneToSixMonths }
        if date > oneYearAgo { return .sixToTwelveMonths }
        return .overOneYear
    }
}
