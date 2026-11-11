@testable import DuplicatesFeature
import Testing

struct MemoizedTests {
    @Test func computesOnceUntilInvalidated() {
        var memo = Memoized<Int>()
        var computations = 0
        let compute = { () -> Int in
            computations += 1
            return 42
        }

        let first = memo.value(computedBy: compute)
        let second = memo.value(computedBy: compute)

        #expect(first == 42)
        #expect(second == 42)
        #expect(computations == 1)
    }

    @Test func computesAgainAfterBeingInvalidated() {
        var memo = Memoized<Int>()
        _ = memo.value { 1 }

        memo.invalidate()
        let value = memo.value { 2 }

        #expect(value == 2)
    }

    @Test func keepsAComputedNil() {
        var memo = Memoized<Int?>()
        var computations = 0
        let compute = { () -> Int? in
            computations += 1
            return nil
        }

        _ = memo.value(computedBy: compute)
        let value = memo.value(computedBy: compute)

        #expect(value == nil)
        #expect(computations == 1)
    }
}
