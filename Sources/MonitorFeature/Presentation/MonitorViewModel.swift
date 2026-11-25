import Combine
import Foundation

/// Keeps the monitor's readings fresh while its screen is on view.
///
/// The screen runs `run()` in a task tied to its appearance, so sampling stops as soon as it
/// goes away. While the app can't be seen at all, such as when it's hidden or minimized,
/// readings are skipped. After either pause, readings and their history start over, so the
/// first reading doesn't show the average of the whole time away.
@MainActor
public final class MonitorViewModel: ObservableObject {
    public static let defaultInterval: Duration = .seconds(MonitorSettings.refreshInterval.defaultValue)
    /// Two minutes of history at the default interval.
    public static let historyLength = 60

    @Published public private(set) var snapshot = SystemSnapshot()
    @Published public private(set) var cpuHistory = SampleHistory<CPUUsage>(capacity: historyLength)
    @Published public var processRanking = ProcessRanking.cpu

    /// Time between readings. `run()` takes a new one from its next wait on, and the history
    /// starts over, since it holds readings taken at the same pace.
    public var interval: Duration {
        didSet {
            guard interval != oldValue else { return }
            cpuHistory = SampleHistory(capacity: Self.historyLength)
        }
    }

    private let sampler: any SystemSampling
    private let isVisible: @MainActor () -> Bool

    /// - Parameters:
    ///   - interval: Time between readings.
    ///   - isVisible: Whether any of the app is on screen, so a reading is worth taking.
    public init(
        sampler: any SystemSampling,
        interval: Duration = defaultInterval,
        isVisible: @escaping @MainActor () -> Bool = { true }
    ) {
        self.sampler = sampler
        self.interval = interval
        self.isVisible = isVisible
    }

    /// The busiest processes in the chosen order.
    public var topProcesses: [ProcessUsage] {
        switch processRanking {
        case .cpu: snapshot.topByCPU
        case .memory: snapshot.topByMemory
        }
    }

    /// Takes a reading every `interval` until the calling task is cancelled, starting over
    /// first and whenever readings were skipped.
    public func run() async {
        var isResuming = true
        while !Task.isCancelled {
            if isVisible() {
                if isResuming {
                    await startOver()
                }
                await refresh()
                isResuming = false
            } else {
                isResuming = true
            }
            try? await Task.sleep(for: interval)
        }
    }

    /// Takes one reading, unless the task is cancelled before or while it's being taken.
    public func refresh() async {
        guard !Task.isCancelled else { return }
        let newSnapshot = await sampler.sample()
        guard !Task.isCancelled else { return }
        snapshot = newSnapshot
        if let cpu = newSnapshot.cpu {
            cpuHistory.append(cpu)
        }
    }

    /// Leaves the readings taken before a pause behind: the history starts over, since the
    /// chart can't show a gap, and the next reading compares with nothing, as the first does.
    private func startOver() async {
        cpuHistory = SampleHistory(capacity: Self.historyLength)
        await sampler.forgetPreviousReading()
    }
}
