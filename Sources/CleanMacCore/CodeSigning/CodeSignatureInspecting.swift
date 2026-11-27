import Foundation

/// Reads the code signature of an app bundle or a program on disk.
public protocol CodeSignatureInspecting: Sendable {
    func facts(forCodeAt url: URL) -> SignatureFacts
}
