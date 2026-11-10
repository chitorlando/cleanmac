import SwiftUI

/// Lets the keyboard drive the disk map as soon as it appears: ↑ and ↓ move through the
/// items, → or Return opens a folder and ← goes up.
///
/// SwiftUI reads the keys itself from macOS 14 on. Earlier systems get the same keys
/// through AppKit.
struct DiskMapKeyboardNavigation: ViewModifier {
    let viewModel: DiskMapViewModel

    func body(content: Content) -> some View {
        if #available(macOS 14, *) {
            content.modifier(DiskMapKeyPressNavigation(viewModel: viewModel))
        } else {
            content.modifier(DiskMapKeyDownNavigation(viewModel: viewModel))
        }
    }
}
