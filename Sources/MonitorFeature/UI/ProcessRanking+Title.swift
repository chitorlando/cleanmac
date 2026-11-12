import SwiftUI

extension ProcessRanking {
    var title: Text {
        switch self {
        case .cpu:
            Text("CPU", bundle: .module, comment: "Title of the processor section of the monitor.")
        case .memory:
            Text("Memory", bundle: .module, comment: "Title of the memory section of the monitor.")
        }
    }
}
