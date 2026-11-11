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
}
