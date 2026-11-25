import CleanMacCore

/// What the user can choose about the large files scan.
public enum LargeFilesSettings {
    /// Smallest size, in bytes, of the files the scan finds.
    public static let minimumSize = Setting(
        key: "largeFiles.minimumSize",
        defaultValue: LargeFileCriteria.defaultMinimumSize,
        allowedValues: [
            10 * ByteSize.megabyte,
            50 * ByteSize.megabyte,
            100 * ByteSize.megabyte,
            500 * ByteSize.megabyte,
            ByteSize.gigabyte
        ]
    )
}
