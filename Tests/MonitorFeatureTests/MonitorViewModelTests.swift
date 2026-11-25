import Foundation
import MonitorFeature
import Testing

@MainActor
struct MonitorViewModelTests {
    private let safari = ProcessUsage(pid: 1, name: "Safari", cpu: 0.8, memoryBytes: 300)
    private let xcode = ProcessUsage(pid: 2, name: "Xcode", cpu: 0.1, memoryBytes: 900)

    private var busy: SystemSnapshot {
        SystemSnapshot(cpu: CPUUsage(user: 0.3, system: 0.1), topByCPU: [safari, xcode], topByMemory: [xcode, safari])
    }

    @Test func showsEachReading() async {
        let viewModel = MonitorViewModel(sampler: FakeSampler([busy]))

        await viewModel.refresh()

        #expect(viewModel.snapshot == busy)
        #expect(viewModel.cpuHistory.values == [CPUUsage(user: 0.3, system: 0.1)])
    }

    @Test func leavesTheFirstReadingOutOfTheHistory() async {
        let viewModel = MonitorViewModel(sampler: FakeSampler([SystemSnapshot(), busy]))

        await viewModel.refresh()
        #expect(viewModel.cpuHistory.isEmpty)
        await viewModel.refresh()
        #expect(viewModel.cpuHistory.count == 1)
    }

    @Test func ordersTheBusiestProcessesAsChosen() async {
        let viewModel = MonitorViewModel(sampler: FakeSampler([busy]))
        await viewModel.refresh()

        #expect(viewModel.topProcesses.map(\.name) == ["Safari", "Xcode"])
        viewModel.processRanking = .memory
        #expect(viewModel.topProcesses.map(\.name) == ["Xcode", "Safari"])
    }

    @Test(.timeLimit(.minutes(1)))
    func keepsReadingUntilCancelled() async {
        let sampler = FakeSampler([busy])
        let viewModel = MonitorViewModel(sampler: sampler, interval: .milliseconds(5))

        let task = Task { await viewModel.run() }
        while sampler.readings < 3 {
            await Task.yield()
            try? await Task.sleep(for: .milliseconds(5))
        }
        task.cancel()
        await task.value
        let readings = sampler.readings
        try? await Task.sleep(for: .milliseconds(30))

        #expect(sampler.readings == readings)
    }

    @Test(.timeLimit(.minutes(1)))
    func skipsReadingsWhileTheAppCannotBeSeen() async {
        let sampler = FakeSampler([busy])
        let viewModel = MonitorViewModel(sampler: sampler, interval: .milliseconds(5), isVisible: { false })

        let task = Task { await viewModel.run() }
        try? await Task.sleep(for: .milliseconds(40))
        task.cancel()
        await task.value

        #expect(sampler.readings == 0)
    }

    @Test func startsTheHistoryOverWhenTheIntervalChanges() async {
        let viewModel = MonitorViewModel(sampler: FakeSampler([busy]), interval: .seconds(2))
        await viewModel.refresh()

        viewModel.interval = .seconds(5)

        #expect(viewModel.cpuHistory.isEmpty)
        #expect(viewModel.snapshot == busy)
    }

    @Test func keepsTheHistoryWhileTheIntervalStaysTheSame() async {
        let viewModel = MonitorViewModel(sampler: FakeSampler([busy]), interval: .seconds(2))
        await viewModel.refresh()

        viewModel.interval = .seconds(2)

        #expect(viewModel.cpuHistory.count == 1)
    }

    @Test(.timeLimit(.minutes(1)))
    func takesUpANewIntervalWhileItRuns() async {
        let sampler = FakeSampler([busy])
        let viewModel = MonitorViewModel(sampler: sampler, interval: .milliseconds(5))

        let task = Task { await viewModel.run() }
        while sampler.readings < 2 {
            await Task.yield()
            try? await Task.sleep(for: .milliseconds(5))
        }
        viewModel.interval = .seconds(3_600)
        // The wait under way still ends at the old pace, and one more reading follows it.
        try? await Task.sleep(for: .milliseconds(200))
        let readings = sampler.readings
        try? await Task.sleep(for: .milliseconds(100))

        #expect(sampler.readings == readings)
        task.cancel()
        await task.value
    }
}
