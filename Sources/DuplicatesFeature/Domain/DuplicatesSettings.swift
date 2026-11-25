import CleanMacCore

/// What the user can choose about the duplicates scan.
public enum DuplicatesSettings {
    /// Smallest size, in bytes, of the files the scan compares.
    public static let minimumSize = Setting(
        key: "duplicates.minimumSize",
        defaultValue: DuplicateScanner.defaultMinimumSize,
        allowedValues: [100_000, 1_000_000, 10_000_000, 100_000_000]
    )
}
