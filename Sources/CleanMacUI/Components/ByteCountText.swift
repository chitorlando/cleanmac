import SwiftUI

public extension Int64 {
    /// Human readable size, such as "1,2 GB".
    var formattedByteCount: String {
        formatted(.byteCount(style: .file))
    }
}
