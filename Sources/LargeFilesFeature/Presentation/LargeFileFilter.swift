import Foundation

/// Narrows the list of large files by kind, age, size and name.
///
/// Every condition left unset lets all files through.
public struct LargeFileFilter: Equatable, Sendable {
    /// Kinds to show. Empty means every kind.
    public var kinds: Set<FileKind>
    public var ageBucket: AgeBucket?
    public var sizeBucket: SizeBucket?
    /// Text the file name must contain, ignoring case and accents.
    public var searchText: String

    public init(
        kinds: Set<FileKind> = [],
        ageBucket: AgeBucket? = nil,
        sizeBucket: SizeBucket? = nil,
        searchText: String = ""
    ) {
        self.kinds = kinds
        self.ageBucket = ageBucket
        self.sizeBucket = sizeBucket
        self.searchText = searchText
    }

    /// `now` and `calendar` decide which age bucket each file falls in.
    public func matches(_ file: LargeFile, now: Date, calendar: Calendar = .current) -> Bool {
        matchesKind(file)
            && matchesAge(file, now: now, calendar: calendar)
            && matchesSize(file)
            && matchesSearch(file)
    }

    public func apply(to files: [LargeFile], now: Date, calendar: Calendar = .current) -> [LargeFile] {
        files.filter { matches($0, now: now, calendar: calendar) }
    }

    private func matchesKind(_ file: LargeFile) -> Bool {
        kinds.isEmpty || kinds.contains(file.kind)
    }

    private func matchesAge(_ file: LargeFile, now: Date, calendar: Calendar) -> Bool {
        guard let ageBucket else { return true }
        return AgeBucket(lastAccessDate: file.lastAccessDate, now: now, calendar: calendar) == ageBucket
    }

    private func matchesSize(_ file: LargeFile) -> Bool {
        guard let sizeBucket else { return true }
        return SizeBucket(size: file.item.size) == sizeBucket
    }

    private func matchesSearch(_ file: LargeFile) -> Bool {
        let term = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !term.isEmpty else { return true }
        return file.item.name.range(of: term, options: [.caseInsensitive, .diacriticInsensitive]) != nil
    }
}
