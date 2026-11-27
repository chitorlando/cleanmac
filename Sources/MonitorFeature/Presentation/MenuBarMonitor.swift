import CleanMacCore
import Combine
import Foundation
import SwiftUI

/// The monitor in the menu bar: an icon, with the processor use next to it when the user
/// chooses, and a menu with the main readings of this Mac and ways back to the app.
///
/// It reads through the monitor's view model, so the menu bar and the monitor's screens share
/// one round of readings at the pace the user chose. It only asks for readings while something
/// shows them: the menu while it's open, and the menu bar while it shows the processor use. The
/// menu also measures the Trash each time it opens.
@MainActor
public final class MenuBarMonitor: ObservableObject {
    /// Whether the icon is in the menu bar, as the user chose in the Settings window. Taking the
    /// icon out of the menu bar, by dragging it away with the Command key held, turns it off.
    ///
    /// Setting what's already the case changes nothing and tells no one. SwiftUI sets it again
    /// each time it updates the menu bar, and the app would otherwise update over and over.
    public var isShown: Bool {
        get { isInMenuBar }
        set {
            guard newValue != isInMenuBar else { return }
            objectWillChange.send()
            isInMenuBar = newValue
            preferences.set(newValue, for: MonitorSettings.showsMenuBarExtra)
            updateMenuBarReadings()
        }
    }

    /// Whether the menu bar shows the processor use next to the icon.
    @Published public private(set) var showsCPU: Bool {
        didSet { updateMenuBarReadings() }
    }

    /// Readings shared with the monitor's screens.
    let monitor: MonitorViewModel
    /// Id of the monitor feature, which the menu opens in the window of the app.
    let featureID: String
    /// The Trash the menu shows and empties.
    let trash: MenuBarTrash
    private let preferences: Preferences
    private var isInMenuBar: Bool
    private var menuReadings: Task<Void, Never>?
    private var menuBarReadings: Task<Void, Never>?
    private var settingChanges: [AnyCancellable] = []

    /// - Parameters:
    ///   - monitor: The view model of the monitor's screens, whose readings it shares.
    ///   - preferences: Where the user chooses whether the icon is in the menu bar and whether
    ///     the processor use shows next to it, which it follows from now on.
    ///   - featureID: See `featureID`.
    ///   - trash: See `trash`.
    public init(monitor: MonitorViewModel, preferences: Preferences, featureID: String, trash: MenuBarTrash) {
        self.monitor = monitor
        self.preferences = preferences
        self.featureID = featureID
        self.trash = trash
        isInMenuBar = preferences.value(of: MonitorSettings.showsMenuBarExtra)
        showsCPU = preferences.value(of: MonitorSettings.showsCPUInMenuBar)
        settingChanges = [
            preferences.changes(of: MonitorSettings.showsMenuBarExtra).sink { [weak self] isShown in
                self?.isShown = isShown
            },
            preferences.changes(of: MonitorSettings.showsCPUInMenuBar).sink { [weak self] showsCPU in
                self?.showsCPU = showsCPU
            }
        ]
        updateMenuBarReadings()
    }

    /// The menu. Its buttons open the window of the app with `openApp`, and the monitor in it
    /// with the `openFeature` action of the environment.
    public func makeMenu(openApp: @escaping @MainActor () -> Void) -> AnyView {
        AnyView(MenuBarMonitorView(menuBar: self, monitor: monitor, openApp: openApp))
    }

    /// The icon in the menu bar, with the processor use next to it when the user chose to see it.
    public func makeLabel() -> AnyView {
        AnyView(MenuBarMonitorLabel(menuBar: self, monitor: monitor))
    }

    /// The sound effects of the menu as they happen: the Trash emptied from it.
    public var soundEffects: AnyPublisher<SoundEffect, Never> {
        trash.soundEffects
    }

    /// What the menu bar shows next to the icon: the processor use, as a whole percentage,
    /// when the user chose to see it, and `nil` otherwise. A dash stands for a use not known yet.
    func menuBarText(locale: Locale = .autoupdatingCurrent) -> String? {
        guard showsCPU else { return nil }
        guard let cpu = monitor.snapshot.cpu else { return "—" }
        return cpu.total.formatted(.percent.precision(.fractionLength(0)).locale(locale))
    }

    /// Reads for the menu while it's open. Readings go on after it closes only while something
    /// else shows them.
    func menuVisibilityDidChange(isOpen: Bool) {
        if isOpen {
            trash.startReading()
            guard menuReadings == nil else { return }
            menuReadings = Task { [monitor] in await monitor.runOnScreen() }
        } else {
            menuReadings?.cancel()
            menuReadings = nil
        }
    }

    /// Reads for the menu bar while it shows the processor use.
    private func updateMenuBarReadings() {
        if isShown && showsCPU {
            guard menuBarReadings == nil else { return }
            menuBarReadings = Task { [monitor] in await monitor.runOnScreen() }
        } else {
            menuBarReadings?.cancel()
            menuBarReadings = nil
        }
    }
}
