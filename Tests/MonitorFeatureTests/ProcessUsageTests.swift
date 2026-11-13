import Foundation
import MonitorFeature
import Testing

struct ProcessUsageTests {
    private func sample(_ pid: Int32, _ name: String, cpu: UInt64, memory: UInt64 = 0) -> ProcessSample {
        ProcessSample(pid: pid, name: name, cpuNanoseconds: cpu, residentBytes: memory)
    }

    @Test func dividesProcessorTimeByTheTimeThatPassed() {
        let usages = ProcessUsageCalculator.usages(
            of: [sample(1, "Safari", cpu: 3_000_000_000), sample(2, "Mail", cpu: 1_500_000_000)],
            since: [1: 1_000_000_000, 2: 1_000_000_000],
            elapsedNanoseconds: 2_000_000_000
        )

        #expect(usages.map(\.cpu) == [1.0, 0.25])
    }

    @Test func countsNewAndReusedProcessesAsIdle() {
        let usages = ProcessUsageCalculator.usages(
            of: [sample(1, "New", cpu: 500), sample(2, "Reused", cpu: 10)],
            since: [2: 900],
            elapsedNanoseconds: 1_000
        )

        #expect(usages.map(\.cpu) == [0, 0])
    }

    @Test func keepsTheMemoryOfEachProcess() {
        let usages = ProcessUsageCalculator.usages(of: [sample(1, "Xcode", cpu: 0, memory: 4_000)], since: [:], elapsedNanoseconds: 0)

        #expect(usages.first?.memoryBytes == 4_000)
    }

    @Test func remembersTheTimesForTheNextReading() {
        #expect(ProcessUsageCalculator.cpuTimes(of: [sample(1, "A", cpu: 5), sample(2, "B", cpu: 9)]) == [1: 5, 2: 9])
    }

    @Test func ranksByProcessorOrMemory() {
        let usages = [
            ProcessUsage(pid: 1, name: "Safari", cpu: 0.2, memoryBytes: 900),
            ProcessUsage(pid: 2, name: "Xcode", cpu: 1.5, memoryBytes: 300),
            ProcessUsage(pid: 3, name: "Mail", cpu: 0.2, memoryBytes: 600)
        ]

        #expect(ProcessRanking.cpu.top(usages, limit: 2).map(\.name) == ["Xcode", "Mail"])
        #expect(ProcessRanking.memory.top(usages, limit: 5).map(\.name) == ["Safari", "Mail", "Xcode"])
    }

    @Test func takesTheAppsNameAndIcon() {
        let usage = ProcessUsage(pid: 1, name: "com.apple.Safari", cpu: 0.1, memoryBytes: 10)
        let app = URL(filePath: "/Applications/Safari.app")

        let shown = usage.identified(as: ProcessIdentity(name: "Safari", iconURL: app))

        #expect(shown.name == "Safari")
        #expect(shown.iconURL == app)
        #expect(usage.identified(as: ProcessIdentity(name: nil, iconURL: nil)).name == "com.apple.Safari")
    }

    @Test func listsTheUsersOwnProcesses() {
        let processes = UserProcessLister().processes()

        #expect(processes.contains { $0.pid == ProcessInfo.processInfo.processIdentifier })
    }
}

struct ProcessUsageAppTests {
    private func process(icon: String?) -> ProcessUsage {
        ProcessUsage(pid: 42, name: "Safari", iconURL: icon.map { URL(filePath: $0) }, cpu: 0, memoryBytes: 0)
    }

    @Test func aProcessOfAnAppBelongsToItsBundle() {
        #expect(process(icon: "/Applications/Safari.app").appURL == URL(filePath: "/Applications/Safari.app"))
        #expect(process(icon: "/Applications/Old.APP").appURL != nil)
    }

    @Test func aBareExecutableOrUnknownIconIsNoApp() {
        #expect(process(icon: "/usr/libexec/trustd").appURL == nil)
        #expect(process(icon: nil).appURL == nil)
    }
}
