import Foundation

extension DuplicateSortOrder {
    var title: String {
        switch self {
        case .recoverableSize:
            String(localized: "Size", bundle: .module, comment: "Sort option that orders groups by the space they can free, largest first.")
        case .name:
            String(localized: "Name", bundle: .module, comment: "Sort option that orders groups alphabetically.")
        }
    }
}
