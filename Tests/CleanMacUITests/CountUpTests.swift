@testable import CleanMacUI
import Testing

struct CountUpTests {
    @Test func startsAtZero() {
        #expect(CountUp.shownValue(for: 0, target: 1_200_000_000) == 0)
    }

    @Test func showsTheWholeNumberReachedSoFar() {
        #expect(CountUp.shownValue(for: 499.4, target: 1_000) == 499)
        #expect(CountUp.shownValue(for: 499.6, target: 1_000) == 500)
    }

    @Test func endsExactlyOnTheTarget() {
        let target: Int64 = 123_456_789_012

        #expect(CountUp.shownValue(for: Double(target), target: target) == target)
    }

    @Test func neverGoesPastTheTargetWhenTheAnimationOvershoots() {
        #expect(CountUp.shownValue(for: 1_080, target: 1_000) == 1_000)
    }

    @Test func neverGoesBelowZeroWhenTheAnimationUndershoots() {
        #expect(CountUp.shownValue(for: -12, target: 1_000) == 0)
    }

    @Test func aTargetOfZeroStaysAtZero() {
        #expect(CountUp.shownValue(for: 0.4, target: 0) == 0)
        #expect(CountUp.shownValue(for: 3, target: 0) == 0)
    }

    @Test func aNumberThatIsNotOneShowsTheTarget() {
        #expect(CountUp.shownValue(for: .nan, target: 42) == 42)
        #expect(CountUp.shownValue(for: .infinity, target: 42) == 42)
    }

    @Test func theLargestTargetDoesNotOverflow() {
        #expect(CountUp.shownValue(for: Double(Int64.max), target: .max) == .max)
    }
}
