import MonitorFeature
import Testing

struct SampleHistoryTests {
    @Test func keepsValuesOldestFirst() {
        var history = SampleHistory<Int>(capacity: 3)
        history.append(1)
        history.append(2)

        #expect(history.values == [1, 2])
        #expect(history.latest == 2)
        #expect(history.count == 2)
    }

    @Test func dropsTheOldestOnceFull() {
        var history = SampleHistory<Int>(capacity: 3)
        (1...5).forEach { history.append($0) }

        #expect(history.values == [3, 4, 5])
        #expect(history.latest == 5)
        #expect(history.count == 3)
    }

    @Test func startsEmpty() {
        let history = SampleHistory<Double>(capacity: 4)

        #expect(history.isEmpty)
        #expect(history.latest == nil)
        #expect(history.values.isEmpty)
    }

    @Test func keepsAtLeastOneValue() {
        var history = SampleHistory<Int>(capacity: 0)
        history.append(7)
        history.append(8)

        #expect(history.values == [8])
    }
}
