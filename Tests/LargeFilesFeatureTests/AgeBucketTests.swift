import Foundation
import LargeFilesFeature
import Testing

struct AgeBucketTests {
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }()

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day))!
    }

    private var now: Date { date(2026, 11, 7) }

    @Test(arguments: [
        ((2026, 11, 6), AgeBucket.lessThanOneMonth),
        ((2026, 10, 8), .lessThanOneMonth),
        ((2026, 10, 7), .oneToSixMonths),
        ((2026, 5, 8), .oneToSixMonths),
        ((2026, 5, 7), .sixToTwelveMonths),
        ((2025, 11, 8), .sixToTwelveMonths),
        ((2025, 11, 7), .overOneYear),
        ((2019, 1, 1), .overOneYear)
    ])
    func groupsByMonthsSinceLastUse(day: (Int, Int, Int), bucket: AgeBucket) {
        let lastUse = date(day.0, day.1, day.2)
        #expect(AgeBucket(lastAccessDate: lastUse, now: now, calendar: calendar) == bucket)
    }

    @Test func treatsFutureDatesAsRecent() {
        let future = date(2027, 1, 1)
        #expect(AgeBucket(lastAccessDate: future, now: now, calendar: calendar) == .lessThanOneMonth)
    }

    @Test func hasNoBucketForUnknownDates() {
        #expect(AgeBucket(lastAccessDate: nil, now: now, calendar: calendar) == nil)
    }
}
