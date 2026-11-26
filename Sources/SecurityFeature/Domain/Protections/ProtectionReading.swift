import Foundation

/// Tells how every protection of this Mac is set.
public protocol ProtectionReading: Sendable {
    /// One check for each `ProtectionKind`, in its order.
    func protections() async -> [ProtectionCheck]
}

/// The files the review reads to tell how protections are set.
public protocol ProtectionFileReading: Sendable {
    /// The dictionary of a property list file, or `nil` when it's missing or can't be read.
    func propertyList(at url: URL) -> [String: Any]?
    func modificationDate(of url: URL) -> Date?
}
