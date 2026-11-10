extension DiskMapViewModel {
    /// Does what a key press asked for.
    func perform(_ action: DiskMapKeyAction) {
        switch action {
        case .moveHighlight(let offset): moveHighlight(by: offset)
        case .openHighlighted: openHighlighted()
        case .goUp: goUp()
        }
    }
}
