import Foundation

struct PS3DIcon: Identifiable, Sendable {
    let title: String
    let fileName: String
    let location: String
    let searchText: String
    var id: String { location + "/" + fileName }

    func url(root: URL, size: Int = 128) -> URL {
        root.appendingPathComponent("size-\(size)/\(location)/\(fileName)")
    }
}

enum PSEmojiIconEntry: Identifiable {
    case emoji(EmojiEntry)
    case icon(PS3DIcon)

    var id: String {
        switch self {
        case .emoji(let entry): "emoji:" + entry.id
        case .icon(let entry): "icon:" + entry.id
        }
    }
}

enum PS3DIconCatalog {
    struct Metadata: Decodable {
        let title: String
        let file_name: String
        let slug: String?
        let category: String?
        let tags: [String]?
        let search_terms_pt_br: [String]?
    }
    struct GeneratedMetadata: Decodable { let description: String }
    struct Catalog: Decodable { let items: [Metadata] }

    static func fold(_ text: String) -> String {
        text.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "pt_BR"))
    }

    static func search(_ entries: [PS3DIcon], query: String) -> [PS3DIcon] {
        let terms = fold(query).split(whereSeparator: \.isWhitespace)
        return entries.filter { entry in terms.allSatisfy { entry.searchText.contains($0) } }
    }

    @concurrent static func load(root: URL) async throws -> [PS3DIcon] {
        let base = root.appendingPathComponent("size-128")
        let translated = base.appendingPathComponent("meta.pt-br.json")
        let canonical = base.appendingPathComponent("meta.json")
        let data = try Data(
            contentsOf: FileManager.default.fileExists(atPath: translated.path) ? translated : canonical)
        let catalog = try JSONDecoder().decode(Catalog.self, from: data)
        var entries = catalog.items.compactMap { item -> PS3DIcon? in
            guard item.file_name == URL(fileURLWithPath: item.file_name).lastPathComponent,
                !item.file_name.isEmpty
            else { return nil }
            let text =
                [item.title, item.file_name, item.slug ?? "", item.category ?? ""]
                + (item.tags ?? []) + (item.search_terms_pt_br ?? [])
            return PS3DIcon(
                title: item.title, fileName: item.file_name, location: "images",
                searchText: fold(text.joined(separator: " ")))
        }
        let generated = base.appendingPathComponent("generated")
        let files =
            (try? FileManager.default.contentsOfDirectory(at: generated, includingPropertiesForKeys: nil))
            ?? []
        for file in files.sorted(by: { $0.lastPathComponent > $1.lastPathComponent })
        where file.pathExtension.lowercased() == "png" {
            let title = file.deletingPathExtension().lastPathComponent.replacingOccurrences(
                of: "-", with: " ")
            let metadataURL = file.appendingPathExtension("json")
            let description =
                (try? Data(contentsOf: metadataURL)).flatMap {
                    try? JSONDecoder().decode(GeneratedMetadata.self, from: $0).description
                } ?? ""
            entries.insert(
                PS3DIcon(
                    title: "IA · " + title, fileName: file.lastPathComponent,
                    location: "generated", searchText: fold(title + " ia gerado 3d " + description)), at: 0)
        }
        return entries
    }
}
