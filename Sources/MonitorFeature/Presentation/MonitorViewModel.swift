import Combine
import Foundation

/// Keeps the monitor's readings fresh while its screen is on view.
///
/// The screen runs `run()` in a task tied to its appearance, so sampling stops as soon as it
/// goes away. While the app can't be seen at all, such as when it's hidden or minimized,
/// readings are skipped.
@MainActor
public final class MonitorViewModel: ObservableObject {
    public static let defaultInterval: Duration = .seconds(2)
    /// Two minutes of history at the default interval.
    public static let historyLength = 60

    @Published public private(set) var snapshot = SystemSnapshot()
    @Published public private(set) var cpuHistory = SampleHistory<CPUUsage>(capacity: historyLength)
    @Published public var processRanking = ProcessRanking.cpu

    private let sampler: any SystemSampling
    private let interval: Duration
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

    /// Takes a reading every `interval` until the calling task is cancelled.
    public func run() async {
        while !Task.isCancelled {
            if isVisible() {
                await refresh()
            }
            try? await Task.sleep(for: interval)
        }
    }

    /// Takes one reading, unless the task is cancelled while it's being taken.
    public func refresh() async {
        let newSnapshot = await sampler.sample()
        guard !Task.isCancelled else { return }
        snapshot = newSnapshot
        if let cpu = newSnapshot.cpu {
            cpuHistory.append(cpu)
        }
    }
}
