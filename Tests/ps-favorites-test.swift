import AppKit

@main
struct PSFavoritesTest {
    @MainActor static func main() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let url = root.appendingPathComponent("folders.json")
        let store = PSFavoriteFolderStore(url: url)
        expect(store.create(name: "Trabalho", member: "app-a"), "creates a folder without changing favorites")
        let work = store.folders[0].id
        expect(!store.create(name: " trabalho "), "folder names are trimmed and cannot duplicate")
        expect(store.create(name: "Pessoal", member: "app-c"), "creates a second group")
        let personal = store.folders[1].id
        expect(store.move("app-b", to: work), "groups another existing favorite")
        let keys = ["app-a", "app-b", "app-c", "app-d"]
        expect(PSFavoriteFolderLayout.tiles(keys: keys, folders: store.folders, open: nil) == [.folder(work), .folder(personal), .item("app-d")], "folders occupy the first member's former slot, without duplicate apps")
        store.open(work)
        expect(PSFavoriteFolderLayout.tiles(keys: keys, folders: store.folders, open: work) == [.item("app-a"), .item("app-b")], "opening a group only shows its members")
        expect(store.exchange("app-a", with: "app-b"), "reorders within a folder")
        expect(store.move("app-b", to: personal), "moves between groups")
        expect(!store.folders[0].members.contains("app-b"), "moving removes the previous membership")
        expect(store.move("app-b", to: nil), "returns a favorite to root")
        expect(store.rename(work, to: "Produção"), "renames a group")
        let reopened = PSFavoriteFolderStore(url: url)
        expect(reopened.document == store.document, "grouping and ordering survive relaunch")
        expect(reopened.remove(work), "ungrouping removes only the container")
        expect(PSFavoriteFolderLayout.tiles(keys: keys, folders: reopened.folders, open: nil).contains(.item("app-a")), "ungrouping returns the member to root")
        expect(PSFavoriteFolderLayout.tiles(keys: ["app-d"], folders: store.folders, open: work).isEmpty, "missing or hidden favorites never become launchable stale entries")
        let bad = root.appendingPathComponent("bad.json")
        let damaged = Data("do not overwrite".utf8)
        try damaged.write(to: bad)
        let blocked = PSFavoriteFolderStore(url: bad)
        expect(!blocked.create(name: "Teste"), "corrupt data cannot be overwritten")
        expect(try Data(contentsOf: bad) == damaged, "corrupt source stays recoverable")
        expect(FavoriteGridLayout.selection(delta: 1, horizontal: true, from: 2, start: 1, count: 12, total: 18) == 3, "right steps one item, including multiple grid rows")
        expect(FavoriteGridLayout.selection(delta: -1, horizontal: true, from: 1, start: 1, count: 12, total: 18) == 1, "left clamps inside Favorites")
        expect(FavoriteGridLayout.selection(delta: 1, horizontal: false, from: 4, start: 1, count: 12, total: 18) == 13, "down skips the entire grid to the following section")
        expect(FavoriteGridLayout.selection(delta: -1, horizontal: false, from: 8, start: 1, count: 12, total: 18) == 0, "up goes to the preceding lead card")
        expect(FavoriteGridLayout.selection(delta: -1, horizontal: false, from: 13, start: 1, count: 12, total: 18) == 1, "up from the following section enters the first favorite")
        expect(FavoriteGridLayout.selection(delta: 1, horizontal: true, from: 13, start: 1, count: 12, total: 18) == nil, "outside Favorites the caret retains horizontal arrows")
        let chord = HotKeyBinding.combo(KeyShortcut(keyCode: 0, modifierFlags: [.command, .option])!)
        let other = HotKeyBinding.combo(KeyShortcut(keyCode: 1, modifierFlags: [.command, .option])!)
        let bindings = ["target": chord, "first": chord, "second": chord, "unrelated": other]
        let owners = PSShortcutConflictPolicy.owners(of: chord, excluding: "target", candidates: ["target", "first", "second", "unrelated", "unset"], lookup: { bindings[$0] }, holdsModifier: { _, _ in false })
        expect(owners == ["first", "second"], "replacement reviews every conflicting owner and excludes itself and unrelated bindings")
        print("PS favorites: all checks passed")
    }

    static func expect(_ condition: Bool, _ message: String) {
        precondition(condition, message)
    }
}
