import SwiftUI

@MainActor
final class PSFavoritesCoordinator {
    unowned let core: AppCore
    private let editor: AppWindowController

    init(core: AppCore) {
        self.core = core
        editor = AppWindowController(
            title: "Favoritos e atalhos", contentSize: CGSize(width: 470, height: 330),
            activation: core.activationPolicy, closesOnEscape: true)
    }

    func edit(_ app: AppEntry, shortcut: Bool) {
        core.paletteCoordinator.hidePalette()
        editor.close()
        editor.show {
            PSItemEditor(app: app, coordinator: self, startRecording: shortcut)
                .shortcutRecorderPopoverHost()
                .environment(core.hotKeys)
                .environment(core.aliases)
        }
    }

    func editFolder(_ folder: PSFavoriteFolder? = nil, member: AppEntry? = nil) {
        core.paletteCoordinator.hidePalette()
        editor.close()
        editor.show { PSFolderEditor(folder: folder, member: member, coordinator: self) }
    }

    func closeEditor() { editor.close() }

    func showFolder(_ id: UUID?) {
        core.psFavoriteFolders.open(id)
        core.palette.selection = 0
        core.palette.focusToken = UUID()
    }

    func itemMenu(_ app: AppEntry, favorite: Bool) -> [PopoverMenuItem] {
        var items: [PopoverMenuItem] = []
        if app.hotKeyAction != nil {
            items.append(PopoverMenuItem(title: "Definir atalho…", systemImage: "keyboard", startsSection: true) {
                self.edit(app, shortcut: true)
            })
        }
        items.append(PopoverMenuItem(title: "Definir alias…", systemImage: "text.cursor", startsSection: items.isEmpty) {
            self.edit(app, shortcut: false)
        })
        items.append(PopoverMenuItem(title: "Criar pasta de favoritos…", systemImage: "folder.badge.plus", startsSection: true) {
            self.editFolder(member: app)
        })
        if favorite, !core.psFavoriteFolders.folders.isEmpty {
            items.append(PopoverMenuItem(title: "Mover para pasta…", systemImage: "folder") {
                self.pickFolder(for: app)
            })
        }
        return items
    }

    func folderMenu(_ folder: PSFavoriteFolder) -> PopoverMenuContent {
        PopoverMenuContent(header: folder.name, items: [
            PopoverMenuItem(title: "Abrir pasta", systemImage: "folder", shortcut: "↵") { self.showFolder(folder.id) },
            PopoverMenuItem(title: "Renomear pasta…", systemImage: "pencil") { self.editFolder(folder) },
            PopoverMenuItem(title: "Criar pasta…", systemImage: "folder.badge.plus") { self.editFolder() },
            PopoverMenuItem(title: "Desagrupar favoritos", systemImage: "folder.badge.minus", startsSection: true) {
                if !self.core.psFavoriteFolders.remove(folder.id) { self.reportFolderError() }
                self.core.palette.selection = 0
            }
        ])
    }

    private func pickFolder(for app: AppEntry) {
        core.paletteCoordinator.hidePalette()
        editor.close()
        editor.show { PSFavoriteFolderPicker(app: app, coordinator: self) }
    }

    func reportFolderError() {
        core.showMessage(core.psFavoriteFolders.errorMessage ?? "Não foi possível alterar a pasta.", tone: .danger)
    }

    func resolveConflict(_ conflict: ShortcutCaptureSession.Conflict, for action: HotKeyAction) async {
        let manager = core.hotKeys
        let owners = manager.conflictingActions(of: conflict.binding, excluding: action)
        let before = owners.map { manager.binding(for: $0) }
        manager.recordingAction = nil
        let names = owners.map(manager.displayName).joined(separator: ", ")
        let choice = await core.choose(
            title: "Atalho já utilizado", message: "Este atalho pertence a \(names). Substituir remove o atalho desses itens e o atribui ao item atual.",
            symbol: "keyboard", options: [
                DialogAction(title: "Escolher outro"), DialogAction(title: "Substituir", role: .destructive),
                DialogAction(title: "Cancelar", role: .cancel)
            ], defaultIndex: 0)
        guard !Task.isCancelled else { return }
        if choice == 0 {
            // The dialog resolves before fading out; return key ownership before recording again.
            guard editor.focus() else { return }
            manager.recordingAction = action
            return
        }
        guard choice == 1 else { return }
        guard manager.conflictingActions(of: conflict.binding, excluding: action) == owners,
            owners.map({ manager.binding(for: $0) }) == before
        else {
            core.showMessage("Os atalhos mudaram. Grave novamente para revisar o conflito.", tone: .neutral)
            return
        }
        for owner in owners { manager.setBinding(nil, for: owner) }
        manager.setBinding(conflict.binding, for: action)
    }
}
