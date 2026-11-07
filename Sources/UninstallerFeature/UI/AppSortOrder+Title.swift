import Foundation

extension AppSortOrder {
    var title: String {
        switch self {
        case .name:
            String(localized: "Name", bundle: .module, comment: "Sort option that orders apps alphabetically.")
        case .size:
            String(localized: "Size", bundle: .module, comment: "Sort option that orders apps by size, largest first.")
        }
    }
}
