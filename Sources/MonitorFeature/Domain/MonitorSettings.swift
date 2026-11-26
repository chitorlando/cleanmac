import CleanMacCore

/// What the user can choose about the monitor.
public enum MonitorSettings {
    /// Seconds between two readings.
    public static let refreshInterval = Setting(key: "monitor.refreshInterval", defaultValue: 2, allowedValues: [1, 2, 5])
    /// Whether the monitor has an icon in the menu bar, with a menu of the main readings.
    public static let showsMenuBarExtra = Setting(key: "monitor.showsMenuBarExtra", defaultValue: true)
    /// Whether the menu bar shows the processor use next to the monitor's icon. The monitor
    /// then reads for as long as the icon is there, every `refreshInterval`.
    public static let showsCPUInMenuBar = Setting(key: "monitor.showsCPUInMenuBar", defaultValue: false)
}
