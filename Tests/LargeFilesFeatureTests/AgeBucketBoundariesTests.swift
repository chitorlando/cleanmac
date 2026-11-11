import Foundation
@testable import LargeFilesFeature
import Testing

struct AgeBucketBoundariesTests {
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }()

    private func date(_ year: Int, _ month: Int, _ day: Int, hour: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour))!
    }

    /// The bucket worked out for a single file, with its own calendar arithmetic.
    private func bucketOnItsOwn(_ lastUse: Date, now: Date) -> AgeBucket {
        func monthsAgo(_ months: Int) -> Date {
            calendar.date(byAdding: .month, value: -months, to: now)!
        }
        if lastUse > monthsAgo(1) { return .lessThanOneMonth }
        if lastUse > monthsAgo(6) { return .oneToSixMonths }
        if lastUse > monthsAgo(12) { return .sixToTwelveMonths }
        return .overOneYear
    }

    @Test(arguments: [(2026, 11, 7), (2026, 3, 31), (2024, 2, 29)])
    func placesEveryDayAsTheFileOnItsOwnWould(today: (Int, Int, Int)) {
        let now = date(today.0, today.1, today.2, hour: 15)
        let boundaries = AgeBucketBoundaries(now: now, calendar: calendar)

        // Every half day over three years, so each boundary is crossed on both sides.
        for halfDays in 0..<(3 * 365 * 2) {
            let lastUse = now.addingTimeInterval(-Double(halfDays) * 43_200)
            #expect(boundaries.bucket(forLastAccessDate: lastUse) == bucketOnItsOwn(lastUse, now: now))
        }
    }

    @Test func placesBoundaryDaysInTheOlderBucket() {
        let boundaries = AgeBucketBoundaries(now: date(2026, 11, 7), calendar: calendar)

        #expect(boundaries.bucket(forLastAccessDate: date(2026, 10, 7)) == .oneToSixMonths)
        #expect(boundaries.bucket(forLastAccessDate: date(2026, 5, 7)) == .sixToTwelveMonths)
        #expect(boundaries.bucket(forLastAccessDate: date(2025, 11, 7)) == .overOneYear)
    }

    @Test func hasNoBucketForUnknownDates() {
        let boundaries = AgeBucketBoundaries(now: date(2026, 11, 7), calendar: calendar)

        #expect(boundaries.bucket(forLastAccessDate: nil) == nil)
    }
}
