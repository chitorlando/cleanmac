import CleanMacCore

/// What the user can choose about the monitor.
public enum MonitorSettings {
    /// Seconds between two readings.
    public static let refreshInterval = Setting(key: "monitor.refreshInterval", defaultValue: 2, allowedValues: [1, 2, 5])
}
