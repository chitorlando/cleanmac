import Foundation

extension AgeBucket {
    var title: String {
        switch self {
        case .lessThanOneMonth:
            String(localized: "Less than a month", bundle: .module, comment: "Last use filter: files used in the last month.")
        case .oneToSixMonths:
            String(localized: "1 to 6 months", bundle: .module, comment: "Last use filter: files last used between 1 and 6 months ago.")
        case .sixToTwelveMonths:
            String(localized: "6 to 12 months", bundle: .module, comment: "Last use filter: files last used between 6 and 12 months ago.")
        case .overOneYear:
            String(localized: "More than a year", bundle: .module, comment: "Last use filter: files not used for over a year.")
        }
    }
}
