import SwiftUI

extension MemoryPressure {
    var title: Text {
        switch self {
        case .normal:
            Text("Normal pressure", bundle: .module, comment: "Badge: macOS has enough memory.")
        case .warning:
            Text("High pressure", bundle: .module, comment: "Badge: macOS is compressing memory and dropping caches.")
        case .critical:
            Text("Critical pressure", bundle: .module, comment: "Badge: memory is short and apps may slow down.")
        }
    }

    var color: Color {
        switch self {
        case .normal: .green
        case .warning: .yellow
        case .critical: .red
        }
    }
}
