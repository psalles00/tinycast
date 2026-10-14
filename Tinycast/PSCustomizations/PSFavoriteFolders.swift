import Foundation

struct PSFavoriteFolder: Codable, Equatable, Identifiable, Sendable {
    let id: UUID
    var name: String
    var members: [String]
}

struct PSFavoriteFolderDocument: Codable, Equatable {
    var version = 1
    var folders: [PSFavoriteFolder] = []
}

enum PSFavoriteTile: Equatable {
    case item(String)
    case folder(UUID)
}

enum PSFavoriteFolderLayout {
    static func tiles(keys: [String], folders: [PSFavoriteFolder], open: UUID?) -> [PSFavoriteTile] {
        if let open, let folder = folders.first(where: { $0.id == open }) {
            let live = Set(keys)
            return folder.members.filter(live.contains).map(PSFavoriteTile.item)
        }
        var shown = Set<UUID>()
        var tiles: [PSFavoriteTile] = []
        for key in keys {
            if let folder = folders.first(where: { $0.members.contains(key) }) {
                if shown.insert(folder.id).inserted { tiles.append(.folder(folder.id)) }
            } else {
                tiles.append(.item(key))
            }
        }
        tiles += folders.filter { !shown.contains($0.id) }.map { .folder($0.id) }
        return tiles
    }
}

@MainActor
@Observable
final class PSFavoriteFolderStore {
    private let url: URL
    private(set) var document = PSFavoriteFolderDocument()
    private(set) var errorMessage: String?
    private(set) var openID: UUID?
    private var writable = true

    var folders: [PSFavoriteFolder] { document.folders }
    var openFolder: PSFavoriteFolder? { folders.first { $0.id == openID } }

    init(url: URL) {
        self.url = url
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        do {
            document = try JSONDecoder().decode(PSFavoriteFolderDocument.self, from: Data(contentsOf: url))
            guard document.version == 1,
                Set(folders.map(\.id)).count == folders.count,
                folders.allSatisfy({ !$0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty })
            else { throw CocoaError(.fileReadCorruptFile) }
        } catch {
            writable = false
            errorMessage = "Não foi possível ler as pastas. O arquivo original foi preservado."
        }
    }

    func open(_ id: UUID?) {
        openID = folders.contains { $0.id == id } ? id : nil
    }

    @discardableResult
    func create(name: String, member: String? = nil) -> Bool {
        let name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty, !folders.contains(where: { $0.name.localizedCaseInsensitiveCompare(name) == .orderedSame }) else {
            errorMessage = "Escolha um nome de pasta único e não vazio."
            return false
        }
        var next = document
        if let member { for i in next.folders.indices { next.folders[i].members.removeAll { $0 == member } } }
        next.folders.append(PSFavoriteFolder(id: UUID(), name: name, members: member.map { [$0] } ?? []))
        return commit(next)
    }

    @discardableResult
    func move(_ key: String, to folderID: UUID?) -> Bool {
        guard folderID == nil || folders.contains(where: { $0.id == folderID }) else { return false }
        var next = document
        for i in next.folders.indices {
            next.folders[i].members.removeAll { $0 == key }
            if next.folders[i].id == folderID { next.folders[i].members.append(key) }
        }
        return commit(next)
    }

    @discardableResult
    func exchange(_ first: String, with second: String) -> Bool {
        guard let folderIndex = folders.firstIndex(where: { $0.id == openID }),
            let a = folders[folderIndex].members.firstIndex(of: first),
            let b = folders[folderIndex].members.firstIndex(of: second)
        else { return false }
        var next = document
        next.folders[folderIndex].members.swapAt(a, b)
        return commit(next)
    }

    @discardableResult
    func rename(_ id: UUID, to name: String) -> Bool {
        let name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty,
            !folders.contains(where: { $0.id != id && $0.name.localizedCaseInsensitiveCompare(name) == .orderedSame }),
            let index = folders.firstIndex(where: { $0.id == id })
        else { errorMessage = "Escolha um nome de pasta único e não vazio."; return false }
        var next = document
        next.folders[index].name = name
        return commit(next)
    }

    @discardableResult
    func remove(_ id: UUID) -> Bool {
        var next = document
        next.folders.removeAll { $0.id == id }
        guard commit(next) else { return false }
        if openID == id { openID = nil }
        return true
    }

    private func commit(_ next: PSFavoriteFolderDocument) -> Bool {
        guard writable else { return false }
        do {
            let data = try JSONEncoder().encode(next)
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try data.write(to: url, options: .atomic)
            document = next
            errorMessage = nil
            return true
        } catch {
            errorMessage = "Não foi possível salvar as pastas: \(error.localizedDescription)"
            return false
        }
    }
}
