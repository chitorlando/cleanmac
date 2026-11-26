import Foundation
import os

/// Remembers the folders each walker made for a scan was told to skip.
final class WalkerRecorder: Sendable {
    private let lists = OSAllocatedUnfairLock<[[URL]]>(initialState: [])

    /// The folders each walker skips, oldest first.
    var excludedDirectories: [[URL]] { lists.withLock { $0 } }

    func record(_ excludedDirectories: [URL]) {
        lists.withLock { $0.append(excludedDirectories) }
    }
}
