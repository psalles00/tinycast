import SwiftUI

struct FavoriteGridEntry: Identifiable {
    enum Content {
        case app(AppEntry)
        case folder(PSFavoriteFolder, count: Int)
    }
    let content: Content
    let slot: Character?

    init(app: AppEntry, slot: Character?) { content = .app(app); self.slot = slot }
    init(folder: PSFavoriteFolder, count: Int, slot: Character?) {
        content = .folder(folder, count: count)
        self.slot = slot
    }
    var id: String {
        switch content {
        case .app(let app): return app.id
        case .folder(let folder, _): return "ps-favorite-folder-" + folder.id.uuidString
        }
    }
    var app: AppEntry? { if case .app(let app) = content { return app }; return nil }
    var name: String {
        switch content { case .app(let app): return app.name; case .folder(let folder, _): return folder.name }
    }
}

struct FavoriteGridView: View {
    let favorites: [FavoriteGridEntry]
    let selectedRowID: String?
    let onActivate: (FavoriteGridEntry) -> Void
    let onActions: (FavoriteGridEntry) -> Void
    @Environment(RunningAppsMonitor.self) private var runningApps

    private let columns = Array(
        repeating: GridItem(.flexible(), spacing: Theme.Spacing.sm),
        count: FavoriteGridLayout.columnCount)

    var body: some View {
        if favorites.isEmpty {
            Text("Pasta vazia. No menu ⌘K de um favorito, escolha Mover para pasta.")
                .font(Theme.Typography.rowTrailing)
                .foregroundStyle(Theme.Colors.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, Theme.Spacing.md)
        }
        LazyVGrid(columns: columns, spacing: Theme.Spacing.sm) {
            ForEach(favorites) { favorite in
                FavoriteGridCell(
                    favorite: favorite,
                    selected: favorite.id == selectedRowID,
                    running: favorite.app.map(runningApps.isRunning) ?? false,
                    slot: favorite.slot
                )
                .contentShape(Rectangle())
                .onTapGesture { onActivate(favorite) }
                .onRightClick { onActions(favorite) }
                .onMiddleClick { onActivate(favorite) }
                .id(favorite.id)
                .selectionFrame(favorite.id == selectedRowID)
            }
        }
        .padding(.bottom, Theme.Spacing.sm)
    }
}

private struct FavoriteGridCell: View {
    let favorite: FavoriteGridEntry
    let selected: Bool
    let running: Bool
    let slot: Character?
    @Environment(PaletteState.self) private var palette
    @State private var hovered = false

    private var fill: Color {
        if selected { return Theme.Colors.selection }
        if hovered { return Theme.Colors.rowHover }
        return .clear
    }

    var body: some View {
        VStack(spacing: Theme.Spacing.xs) {
            icon
                .frame(width: 44, height: 44)
                .overlay(alignment: .bottomTrailing) {
                    if running {
                        Circle()
                            .fill(.secondary)
                            .frame(width: 4, height: 4)
                    }
                }
            Text(favorite.name)
                .font(Theme.Typography.rowTrailing)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity, minHeight: 80)
        .padding(.horizontal, Theme.Spacing.xs)
        .padding(.vertical, Theme.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.row, style: .continuous)
                .fill(fill)
        )
        .overlay(alignment: .topTrailing) {
            if let slot, palette.commandHeld {
                KeyCapChip(text: String(slot), style: .outline)
                    .padding(Theme.Spacing.xxs)
            }
        }
        .armedHover($hovered)
        .accessibilityLabel(favorite.name)
    }

    @ViewBuilder
    private var icon: some View {
        switch favorite.content {
        case .app(let app): AppIconView(app: app, pointSize: 44)
        case .folder(_, let count):
            SymbolImage(name: "folder.fill", size: 40)
                .foregroundStyle(Theme.Colors.textSecondary)
                .overlay(alignment: .bottomTrailing) {
                    Text("\(count)")
                        .font(Theme.Typography.keyCap)
                        .padding(3)
                        .background(Theme.Colors.selection, in: Circle())
                }
        }
    }
}
