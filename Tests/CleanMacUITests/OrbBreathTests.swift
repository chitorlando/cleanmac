@testable import CleanMacUI
import Foundation
import Testing

struct OrbBreathTests {
    private let period = Motion.breathPeriod

    @Test func breathesInAndOutOnceAPeriod() {
        #expect(abs(OrbBreath.value(at: 0) - 0.5) < 1e-9)
        #expect(abs(OrbBreath.value(at: period / 4) - 1) < 1e-9)
        #expect(abs(OrbBreath.value(at: period * 3 / 4)) < 1e-9)
        #expect(abs(OrbBreath.value(at: period) - OrbBreath.value(at: 0)) < 1e-9)
    }

    @Test func staysBetweenItsSmallestAndLargest() {
        for time in stride(from: 0.0, through: 3 * period, by: 0.13) {
            let breath = OrbBreath.value(at: time)
            #expect(breath >= 0 && breath <= 1)
        }
    }

    @Test func aStillGlowRestsHalfway() {
        #expect(OrbBreath.still == 0.5)
    }
}
