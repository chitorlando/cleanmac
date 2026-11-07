import Foundation

extension SizeBucket {
    var title: String {
        switch self {
        case .from50MBTo100MB:
            String(localized: "50 to 100 MB", bundle: .module, comment: "Size filter: files from 50 MB up to 100 MB.")
        case .from100MBTo1GB:
            String(localized: "100 MB to 1 GB", bundle: .module, comment: "Size filter: files from 100 MB up to 1 GB.")
        case .over1GB:
            String(localized: "More than 1 GB", bundle: .module, comment: "Size filter: files of 1 GB or more.")
        }
    }
}
