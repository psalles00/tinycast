import SwiftUI

extension PSFavoriteFolderStore {
    func entries(for apps: [AppEntry]) -> [FavoriteGridEntry] {
        let byKey = Dictionary(apps.map { ($0.preferenceKey, $0) }, uniquingKeysWith: { first, _ in first })
        return PSFavoriteFolderLayout.tiles(keys: apps.map(\.preferenceKey), folders: folders, open: openID)
            .enumerated().compactMap { index, tile in
                let slot = FavoriteSlots.digit(at: index)
                switch tile {
                case .item(let key): return byKey[key].map { FavoriteGridEntry(app: $0, slot: slot) }
                case .folder(let id):
                    guard let folder = folders.first(where: { $0.id == id }) else { return nil }
                    return FavoriteGridEntry(folder: folder, count: folder.members.filter { byKey[$0] != nil }.count, slot: slot)
                }
            }
    }
}
