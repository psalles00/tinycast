import Foundation

@main
struct PSIconsTest {
    static func main() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let base = root.appendingPathComponent("size-128")
        let generated = base.appendingPathComponent("generated")
        try FileManager.default.createDirectory(at: generated, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let data = try JSONSerialization.data(withJSONObject: ["items": [
            ["title": "Apple", "file_name": "apple.png", "search_terms_pt_br": ["maçã", "fruta vermelha"]],
            ["title": "Unsafe", "file_name": "../escape.png"]
        ]])
        try data.write(to: base.appendingPathComponent("meta.pt-br.json"))
        try Data().write(to: generated.appendingPathComponent("ai-console.png"))
        try Data(#"{"description":"Controle portátil de jogos"}"#.utf8)
            .write(to: generated.appendingPathComponent("ai-console.png.json"))
        let entries = try await PS3DIconCatalog.load(root: root)
        expect(entries.count == 2, "catalog includes generated images and rejects path traversal")
        expect(
            PS3DIconCatalog.search(entries, query: "MACA").first?.fileName == "apple.png",
            "Portuguese accent and case insensitive search")
        expect(
            PS3DIconCatalog.search(entries, query: "vermelha fruta").count == 1,
            "every term matches regardless of order")
        expect(
            PS3DIconCatalog.search(entries, query: "fruta jogos").isEmpty, "terms cannot span unrelated icons"
        )
        expect(
            PS3DIconCatalog.search(entries, query: "portatil").first?.location == "generated",
            "generated descriptions are searchable")
        let icon = entries[0]
        expect(
            icon.url(root: root, size: 1024).path.hasSuffix("size-1024/generated/ai-console.png"),
            "resolution preserves generated location")
        expect(
            EmojiCategoryFilter.allCases.contains(.icons3D), "3D has its own category in the merged picker")
        let geometry = EmojiGridGeometry(counts: [3, 10], columns: 8)
        expect(
            geometry.down(from: 2) == 5, "vertical navigation crosses the mixed section boundary by column")
        expect(geometry.up(from: 5) == 2, "returning to emojis preserves the column")
        expect(
            try Data(contentsOf: base.appendingPathComponent("meta.pt-br.json")) == data,
            "catalog is read only")
        print("PS 3D icons: passed")
    }

    static func expect(_ value: Bool, _ label: String) {
        guard value else { fatalError(label) }
    }
}
