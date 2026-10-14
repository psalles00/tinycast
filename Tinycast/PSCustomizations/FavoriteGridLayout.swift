enum FavoriteGridLayout {
    static let columnCount = 8

    static func selection(delta: Int, horizontal: Bool, from selection: Int, start: Int, count: Int, total: Int) -> Int? {
        guard count > 0, total > 0 else { return nil }
        let end = start + count
        if horizontal {
            guard (start..<end).contains(selection) else { return nil }
            return min(max(selection + delta, start), end - 1)
        }
        if (start..<end).contains(selection) {
            return delta > 0 ? min(end, total - 1) : max(start - 1, 0)
        }
        if delta < 0, selection == end { return start }
        return nil
    }
}
