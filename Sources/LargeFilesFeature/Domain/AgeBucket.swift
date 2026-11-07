import Foundation

/// How long ago a file was last used, in ranges the user can filter by.
public enum AgeBucket: CaseIterable, Sendable {
    case lessThanOneMonth
    case oneToSixMonths
    case sixToTwelveMonths
    case overOneYear

    /// The bucket of a file last used on `date`, or `nil` when the date is unknown.
    public init?(lastAccessDate date: Date?, now: Date, calendar: Calendar = .current) {
        guard let date else { return nil }
        func monthsAgo(_ months: Int) -> Date {
            calendar.date(byAdding: .month, value: -months, to: now) ?? now
        }

        if date > monthsAgo(1) {
            self = .lessThanOneMonth
        } else if date > monthsAgo(6) {
            self = .oneToSixMonths
        } else if date > monthsAgo(12) {
            self = .sixToTwelveMonths
        } else {
            self = .overOneYear
        }
    }
}
