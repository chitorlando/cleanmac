import CleanMacCore
import Foundation
@testable import MonitorFeature
import Testing

@MainActor
struct MenuBarMonitorTests {
    private let busy = SystemSnapshot(cpu: CPUUsage(user: 0.2, system: 0.034))
    private let english = Locale(identifier: "en_US")

    /// A menu bar monitor whose readings come from `sampler`, every `interval`. No window of
    /// the app can be seen, so only the menu bar monitor asks for readings.
    private func makeMenuBar(
        sampler: FakeSampler,
        preferences: Preferences? = nil,
        interval: Duration = .milliseconds(5)
    ) -> MenuBarMonitor {
        let monitor = MonitorViewModel(sampler: sampler, interval: interval, isVisible: { false })
        let preferences = preferences ?? Preferences(storage: InMemoryPreferenceStorage())
        return MenuBarMonitor(monitor: monitor, preferences: preferences, featureID: "monitor")
    }

    /// Checks `condition` a little at a time until it holds. The tests' time limits end a wait
    /// that never does.
    private func waitUntil(_ condition: () -> Bool) async {
        while !condition() {
            await Task.yield()
            try? await Task.sleep(for: .milliseconds(5))
        }
    }

    /// Waits until `sampler` takes no new reading for a while, as once the readings stop.
    private func waitUntilReadingsStop(_ sampler: FakeSampler) async {
        var readings = -1
        while sampler.readings != readings {
            readings = sampler.readings
            try? await Task.sleep(for: .milliseconds(50))
        }
    }

    @Test func isInTheMenuBarWithOnlyItsIconUntilTheUserChooses() {
        let menuBar = makeMenuBar(sampler: FakeSampler([]))

        #expect(menuBar.isShown)
        #expect(!menuBar.showsCPU)
    }

    @Test func startsAsTheUserChose() {
        let storage = InMemoryPreferenceStorage(["monitor.showsMenuBarExtra": false, "monitor.showsCPUInMenuBar": true])

        let menuBar = makeMenuBar(sampler: FakeSampler([]), preferences: Preferences(storage: storage))

        #expect(!menuBar.isShown)
        #expect(menuBar.showsCPU)
    }

    @Test func followsTheChoicesOfTheSettingsWindow() {
        let preferences = Preferences(storage: InMemoryPreferenceStorage())
        let menuBar = makeMenuBar(sampler: FakeSampler([]), preferences: preferences)

        preferences.set(false, for: MonitorSettings.showsMenuBarExtra)
        preferences.set(true, for: MonitorSettings.showsCPUInMenuBar)

        #expect(!menuBar.isShown)
        #expect(menuBar.showsCPU)
    }

    @Test func remembersWhenItIsTakenOutOfTheMenuBar() {
        let preferences = Preferences(storage: InMemoryPreferenceStorage())
        let menuBar = makeMenuBar(sampler: FakeSampler([]), preferences: preferences)

        menuBar.isShown = false

        #expect(preferences.value(of: MonitorSettings.showsMenuBarExtra) == false)
    }

    /// SwiftUI sets whether the icon is in the menu bar again each time it updates the menu bar.
    /// Telling about it would have SwiftUI update the menu bar again, and so on forever.
    @Test func tellsNothingWhenToldWhatIsAlreadyTheCase() {
        let menuBar = makeMenuBar(sampler: FakeSampler([]))
        var changes = 0
        let observation = menuBar.objectWillChange.sink { changes += 1 }

        menuBar.isShown = true
        #expect(changes == 0)
        menuBar.isShown = false
        #expect(changes == 1)
        observation.cancel()
    }

    @Test func opensTheMonitorFeature() {
        let module = MonitorModule(viewModel: MonitorViewModel(sampler: FakeSampler([])), preferences: Preferences(storage: InMemoryPreferenceStorage()))

        #expect(module.menuBarMonitor.featureID == module.id)
    }

    @Test(.timeLimit(.minutes(1)))
    func readsNothingWhileItsMenuIsClosed() async {
        let sampler = FakeSampler([busy])
        let menuBar = makeMenuBar(sampler: sampler)

        try? await Task.sleep(for: .milliseconds(50))

        #expect(sampler.readings == 0)
        withExtendedLifetime(menuBar) {}
    }

    @Test(.timeLimit(.minutes(1)))
    func readsWhileItsMenuIsOpen() async {
        let sampler = FakeSampler([busy])
        let menuBar = makeMenuBar(sampler: sampler)

        menuBar.menuVisibilityDidChange(isOpen: true)
        await waitUntil { sampler.readings >= 2 }
        menuBar.menuVisibilityDidChange(isOpen: false)
        await waitUntilReadingsStop(sampler)
        let readings = sampler.readings
        try? await Task.sleep(for: .milliseconds(30))

        #expect(sampler.readings == readings)
        #expect(menuBar.monitor.snapshot == busy)
    }

    @Test(.timeLimit(.minutes(1)))
    func readsForTheMenuBarWhileItShowsTheCPU() async {
        let sampler = FakeSampler([busy])
        let preferences = Preferences(storage: InMemoryPreferenceStorage())
        let menuBar = makeMenuBar(sampler: sampler, preferences: preferences)

        preferences.set(true, for: MonitorSettings.showsCPUInMenuBar)
        await waitUntil { sampler.readings >= 2 }
        preferences.set(false, for: MonitorSettings.showsCPUInMenuBar)
        await waitUntilReadingsStop(sampler)
        let readings = sampler.readings
        try? await Task.sleep(for: .milliseconds(30))

        #expect(sampler.readings == readings)
        withExtendedLifetime(menuBar) {}
    }

    @Test(.timeLimit(.minutes(1)))
    func keepsReadingForTheMenuBarAfterItsMenuCloses() async {
        let sampler = FakeSampler([busy])
        let preferences = Preferences(storage: InMemoryPreferenceStorage(["monitor.showsCPUInMenuBar": true]))
        let menuBar = makeMenuBar(sampler: sampler, preferences: preferences)

        menuBar.menuVisibilityDidChange(isOpen: true)
        await waitUntil { sampler.readings >= 2 }
        menuBar.menuVisibilityDidChange(isOpen: false)
        let readings = sampler.readings
        await waitUntil { sampler.readings >= readings + 2 }

        // One round of readings for both, never started over when the menu closed.
        #expect(sampler.calls.filter { $0 == .forgetPreviousReading }.count == 1)
        preferences.set(false, for: MonitorSettings.showsCPUInMenuBar)
        await waitUntilReadingsStop(sampler)
        withExtendedLifetime(menuBar) {}
    }

    @Test(.timeLimit(.minutes(1)))
    func stopsReadingForTheMenuBarOnceItLeavesIt() async {
        let sampler = FakeSampler([busy])
        let preferences = Preferences(storage: InMemoryPreferenceStorage(["monitor.showsCPUInMenuBar": true]))
        let menuBar = makeMenuBar(sampler: sampler, preferences: preferences)

        await waitUntil { sampler.readings >= 2 }
        menuBar.isShown = false
        await waitUntilReadingsStop(sampler)
        let readings = sampler.readings
        try? await Task.sleep(for: .milliseconds(30))

        #expect(sampler.readings == readings)
        #expect(menuBar.showsCPU)
    }

    @Test func showsOnlyItsIconUntilTheUserAsksForTheCPU() async {
        let menuBar = makeMenuBar(sampler: FakeSampler([busy]))
        await menuBar.monitor.refresh()

        #expect(menuBar.menuBarText(locale: english) == nil)
    }

    @Test(.timeLimit(.minutes(1)))
    func showsTheCPUAsAWholePercentage() async {
        // The first reading has nothing to compare with, so the use isn't known yet.
        let first = SystemSnapshot(memoryPressure: .normal)
        let sampler = FakeSampler([first, busy])
        let preferences = Preferences(storage: InMemoryPreferenceStorage(["monitor.showsCPUInMenuBar": true]))
        let menuBar = makeMenuBar(sampler: sampler, preferences: preferences, interval: .seconds(3_600))

        await waitUntil { menuBar.monitor.snapshot == first }
        #expect(menuBar.menuBarText(locale: english) == "—")
        await menuBar.monitor.refresh()
        #expect(menuBar.menuBarText(locale: english) == "23%")

        preferences.set(false, for: MonitorSettings.showsCPUInMenuBar)
        await waitUntilReadingsStop(sampler)
    }
}
