import Foundation
import SecurityFeature
import Testing

struct XProtectEvaluatorTests {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)
    private let day: TimeInterval = 24 * 60 * 60

    @Test func isOnWithRecentDefinitions() {
        let updatedAt = now.addingTimeInterval(-13 * day)

        let check = XProtectEvaluator.check(bundles: [XProtectBundle(version: "5377", updatedAt: updatedAt)], now: now)

        #expect(check == ProtectionCheck(kind: .xprotect, state: .on, detail: .xprotect(version: "5377", updatedAt: updatedAt)))
    }

    @Test func isOutdatedWhenTheDefinitionsAreMonthsOld() {
        let updatedAt = now.addingTimeInterval(-120 * day)

        #expect(XProtectEvaluator.check(bundles: [XProtectBundle(version: "5200", updatedAt: updatedAt)], now: now).state == .outdated)
    }

    /// macOS 15 and later keep a second copy that they update, next to one that may lag.
    @Test func usesTheNewestCopy() {
        let old = XProtectBundle(version: "5200", updatedAt: now.addingTimeInterval(-200 * day))
        let current = XProtectBundle(version: "5400", updatedAt: now.addingTimeInterval(-3 * day))

        let check = XProtectEvaluator.check(bundles: [old, current], now: now)

        #expect(check.state == .on)
        #expect(check.detail == .xprotect(version: "5400", updatedAt: current.updatedAt))
    }

    @Test func isUnknownWithoutDefinitions() {
        #expect(XProtectEvaluator.check(bundles: [], now: now) == ProtectionCheck(kind: .xprotect, state: .unknown))
    }
}
