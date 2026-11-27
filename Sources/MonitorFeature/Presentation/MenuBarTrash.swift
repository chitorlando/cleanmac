import CleanMacCore
import Foundation

/// The Trash in the menu of the menu bar monitor: how much it holds, read each time the menu
/// opens, and a way to empty it.
///
/// Emptying the Trash erases what it holds for good, so nothing is emptied until the user
/// confirms it in the dialog `requestEmpty()` brings up, whose confirming button calls `empty()`.
@MainActor
public final class MenuBarTrash: ObservableObject {
    /// What the Trash holds, as last read: `nil` until the first reading ends.
    @Published public private(set) var usage: TrashUsage?
    /// Whether the dialog that asks before emptying the Trash is up.
    @Published public private(set) var isConfirmingEmpty = false
    @Published public private(set) var isEmptying = false
    /// Why the Trash couldn't be emptied the last time, or `nil` when it could.
    @Published public private(set) var emptyingFailure: CleanupFailureKind?

    private let reader: any TrashUsageReading
    private let service: TrashEmptyingService
    private let homeBin: URL
    private var reading: Task<Void, Never>?

    /// - Parameters:
    ///   - reader: Measures the Trash.
    ///   - service: Empties the Trash.
    ///   - homeBin: The bin in the home folder, which stands for the whole Trash when it
    ///     couldn't be measured.
    public init(reader: any TrashUsageReading, service: TrashEmptyingService, homeBin: URL) {
        self.reader = reader
        self.service = service
        self.homeBin = homeBin
    }

    /// Bytes the Trash holds, or `nil` while that isn't known.
    var size: Int64? {
        guard case .readable(let bins) = usage else { return nil }
        return bins.reduce(0) { $0 + $1.size }
    }

    /// Whether the Trash can be emptied: not while it's being emptied, nor when it's known to
    /// be empty. A Trash that couldn't be measured may hold something, so it can.
    var canEmpty: Bool {
        !isEmptying && usage != .readable([])
    }

    /// Reads the Trash again, away from the main thread, unless a reading is already under way.
    func startReading() {
        guard reading == nil else { return }
        reading = Task {
            await read()
            reading = nil
        }
    }

    /// Reads the Trash, away from the main thread.
    func read() async {
        let reader = reader
        usage = await Task.detached(priority: .utility) { reader.read() }.value
    }

    /// Asks the user whether to empty the Trash. Nothing is erased until they confirm it.
    func requestEmpty() {
        guard canEmpty else { return }
        emptyingFailure = nil
        isConfirmingEmpty = true
    }

    /// Stops asking, without erasing anything.
    func cancelEmpty() {
        if isConfirmingEmpty {
            isConfirmingEmpty = false
        }
    }

    /// Empties the Trash, once the user confirmed it, and then reads it again.
    func empty() async {
        cancelEmpty()
        guard canEmpty else { return }
        isEmptying = true
        let report = await service.empty(bins)
        // Finder empties every bin at once, so they all fail for the same reason.
        emptyingFailure = report.failures.first?.kind
        isEmptying = false
        await read()
    }

    /// The bins to empty: those that hold something, or the one in the home folder for the
    /// whole Trash when it couldn't be measured. Finder empties every bin either way.
    private var bins: [CleanableItem] {
        guard case .readable(let usages) = usage else {
            return [CleanableItem(url: homeBin, size: 0)]
        }
        return usages.map { CleanableItem(url: $0.bin.url, size: $0.size) }
    }
}

public extension MenuBarTrash {
    /// The user's Trash, measured as macOS lets CleanMac and emptied by Finder.
    static func live() -> MenuBarTrash {
        let home = FileManager.default.homeDirectoryForCurrentUser
        return MenuBarTrash(
            reader: TrashSizeReader(home: home),
            service: TrashEmptyingService(),
            homeBin: home.appending(path: ".Trash", directoryHint: .isDirectory)
        )
    }
}
