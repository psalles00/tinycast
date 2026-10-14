import SwiftUI

struct PSItemEditor: View {
    let app: AppEntry
    let coordinator: PSFavoritesCoordinator
    let startRecording: Bool
    @Environment(HotKeyManager.self) private var hotKeys
    @Environment(AliasStore.self) private var aliases
    @State private var alias = ""
    @State private var conflictTask: Task<Void, Never>?
    @FocusState private var aliasFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            Text(app.name).font(Theme.Typography.panelTitle)
            Text("Alias").foregroundStyle(Theme.Colors.textSecondary)
            TextField("Nome curto para buscar este item", text: $alias)
                .textFieldStyle(.roundedBorder)
                .focused($aliasFocused)
            if let action = app.hotKeyAction {
                HStack {
                    Text("Atalho global")
                    Spacer()
                    ShortcutRecorder(action: action)
                }
                Text("Clique para gravar. Escape cancela; Delete remove o atalho. Alterações do atalho são salvas imediatamente.")
                    .font(Theme.Typography.rowTrailing)
                    .foregroundStyle(Theme.Colors.textSecondary)
            }
            Spacer()
            HStack {
                Button("Fechar") { coordinator.closeEditor() }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button("Salvar alias") {
                    aliases.setAlias(alias, for: app.preferenceKey)
                    coordinator.closeEditor()
                }.keyboardShortcut(.defaultAction)
            }
        }
        .padding(Theme.Spacing.xl)
        .onAppear {
            alias = aliases.alias(for: app.preferenceKey) ?? ""
        }
        .task {
            await Task.yield()
            guard !Task.isCancelled else { return }
            if startRecording, let action = app.hotKeyAction { hotKeys.recordingAction = action }
            else { aliasFocused = true }
        }
        .onChange(of: hotKeys.capture.conflict) { _, conflict in
            guard let conflict, let action = app.hotKeyAction, hotKeys.recordingAction == action else { return }
            conflictTask?.cancel()
            conflictTask = Task { await coordinator.resolveConflict(conflict, for: action) }
        }
        .onDisappear {
            conflictTask?.cancel()
            if hotKeys.recordingAction == app.hotKeyAction { hotKeys.recordingAction = nil }
        }
    }
}

struct PSFolderEditor: View {
    let folder: PSFavoriteFolder?
    let member: AppEntry?
    let coordinator: PSFavoritesCoordinator
    @State private var name = ""
    @State private var error: String?
    @FocusState private var focused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            Text(folder == nil ? "Nova pasta de favoritos" : "Renomear pasta")
                .font(Theme.Typography.panelTitle)
            TextField("Nome da pasta", text: $name).textFieldStyle(.roundedBorder).focused($focused)
            if let member { Text("\(member.name) será adicionado à pasta.").foregroundStyle(Theme.Colors.textSecondary) }
            if let error { Text(error).foregroundStyle(.red).font(Theme.Typography.rowTrailing) }
            Spacer()
            HStack {
                Button("Cancelar") { coordinator.closeEditor() }.keyboardShortcut(.cancelAction)
                Spacer()
                Button("Salvar") { save() }.keyboardShortcut(.defaultAction)
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(Theme.Spacing.xl)
        .onAppear { name = folder?.name ?? "" }
        .task {
            await Task.yield()
            guard !Task.isCancelled else { return }
            focused = true
        }
    }

    private func save() {
        let core = coordinator.core
        let saved = folder.map { core.psFavoriteFolders.rename($0.id, to: name) }
            ?? core.psFavoriteFolders.create(name: name, member: member?.preferenceKey)
        guard saved else { error = core.psFavoriteFolders.errorMessage; return }
        if let member, !core.favorites.isFavorite(member) { core.favorites.toggle(member) }
        coordinator.closeEditor()
    }
}
