/// What a volume reports about the data a file shares with other files.
///
/// On APFS, copying a file usually makes a clone: a new file that shares the original's
/// data on disk until one of them changes. Removing a clone frees no space while
/// another file still shares its data.
public struct CloneInfo: Hashable, Sendable {
    /// Identifies a file's data on disk: a volume and a data stream on it.
    public struct StreamID: Hashable, Sendable {
        public let device: Int64
        /// Pure clones of each other report the same value.
        public let cloneID: UInt64

        public init(device: Int64, cloneID: UInt64) {
            self.device = device
            self.cloneID = cloneID
        }
    }

    public let streamID: StreamID
    /// Files that share all of this data, this one included: 1 when the file has no clones.
    ///
    /// `nil` when the system can't count them, as on macOS 13: the file may then have any
    /// number of clones, in the group or outside it, so no space can be promised for it.
    public let cloneCount: Int?
    /// The file may share part of its data with files that are not clones of it, such as a
    /// clone that was later modified, so removing it frees an unknown amount of space.
    ///
    /// The volume keeps reporting it after the other files are gone, so it may be a false alarm.
    public let mayShareSomeData: Bool

    public init(streamID: StreamID, cloneCount: Int?, mayShareSomeData: Bool) {
        self.streamID = streamID
        self.cloneCount = cloneCount
        self.mayShareSomeData = mayShareSomeData
    }
}
