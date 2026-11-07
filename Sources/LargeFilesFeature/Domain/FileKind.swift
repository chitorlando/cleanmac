import Foundation
import UniformTypeIdentifiers

/// Broad family of a file, used to group and filter large files.
public enum FileKind: String, CaseIterable, Sendable {
    case archive
    case diskImage
    case video
    case audio
    case image
    case document
    case other

    /// Families checked in order, so the more specific match wins:
    /// disk images are also archives, and Office documents are also zip archives.
    private static let conformances: [(FileKind, [UTType])] = [
        (.diskImage, [.diskImage]),
        (.document, [.pdf, .presentation, .spreadsheet, .text, .compositeContent]),
        (.video, [.movie]),
        (.audio, [.audio]),
        (.image, [.image]),
        (.archive, [.archive])
    ]

    public init(contentType: UTType?) {
        guard let contentType else {
            self = .other
            return
        }
        let match = Self.conformances.first { _, types in
            types.contains { contentType.conforms(to: $0) }
        }
        self = match?.0 ?? .other
    }

    /// Classifies a file by its name extension.
    public init(url: URL) {
        self.init(contentType: UTType(filenameExtension: url.pathExtension))
    }
}
