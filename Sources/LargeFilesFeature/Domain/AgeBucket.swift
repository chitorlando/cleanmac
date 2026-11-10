import Foundation

/// How long ago a file was last used, in ranges the user can filter by.
public enum AgeBucket: CaseIterable, Sendable {
    case lessThanOneMonth
    case oneToSixMonths
    case sixToTwelveMonths
    case overOneYear

    /// The bucket of a file last used on `date`, or `nil` when the date is unknown.
    ///
    /// To place many files on the same day, `AgeBucketBoundaries` works the dates out once.
    public init?(lastAccessDate date: Date?, now: Date, calendar: Calendar = .current) {
        guard let bucket = AgeBucketBoundaries(now: now, calendar: calendar).bucket(forLastAccessDate: date) else {
            return nil
        }
        self = bucket
    }
}
