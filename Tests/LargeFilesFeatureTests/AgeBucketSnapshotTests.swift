import Foundation
@testable import LargeFilesFeature
import Testing

struct AgeBucketSnapshotTests {
    private typealias Fixtures = LargeFileFixtures

    private let snapshot = AgeBucketSnapshot(now: Fixtures.now, calendar: Fixtures.calendar)

    @Test(arguments: [0.0, 1, 59.9, -59.9])
    func staysCurrentForLessThanAMinute(seconds: TimeInterval) {
        #expect(snapshot.isCurrent(at: Fixtures.now.addingTimeInterval(seconds)))
    }

    @Test(arguments: [60.0, 3_600, 86_400])
    func isOutdatedAMinuteLater(seconds: TimeInterval) {
        #expect(!snapshot.isCurrent(at: Fixtures.now.addingTimeInterval(seconds)))
    }

    @Test func isOutdatedWhenTheClockIsSetBack() {
        #expect(!snapshot.isCurrent(at: Fixtures.now.addingTimeInterval(-60)))
        #expect(!snapshot.isCurrent(at: Fixtures.date(2026, 1, 1)))
    }

    @Test func hasTheAgeRangesOfItsMoment() {
        let boundaries = snapshot.boundaries

        #expect(boundaries.bucket(forLastAccessDate: Fixtures.date(2026, 11, 1)) == .lessThanOneMonth)
        #expect(boundaries.bucket(forLastAccessDate: Fixtures.date(2026, 10, 7)) == .oneToSixMonths)
        #expect(boundaries.bucket(forLastAccessDate: Fixtures.date(2026, 5, 7)) == .sixToTwelveMonths)
        #expect(boundaries.bucket(forLastAccessDate: Fixtures.date(2025, 11, 7)) == .overOneYear)
    }
}
