import SwiftUI

struct FavoriteGridEntry: Identifiable {
    let app: AppEntry
    let slot: Character?
    var id: String { app.id }
}

struct FavoriteGridView: View {
    let favorites: [FavoriteGridEntry]
    let selectedRowID: String?
    let onActivate: (AppEntry) -> Void
    let onActions: (AppEntry) -> Void
    @Environment(RunningAppsMonitor.self) private var runningApps

    private let columns = Array(
        repeating: GridItem(.flexible(), spacing: Theme.Spacing.sm),
        count: FavoriteGridLayout.columnCount)

    var body: some View {
        LazyVGrid(columns: columns, spacing: Theme.Spacing.sm) {
            ForEach(favorites) { favorite in
                FavoriteGridCell(
                    app: favorite.app,
                    selected: favorite.id == selectedRowID,
                    running: runningApps.isRunning(favorite.app),
                    slot: favorite.slot
                )
                .contentShape(Rectangle())
                .onTapGesture { onActivate(favorite.app) }
                .onRightClick { onActions(favorite.app) }
                .onMiddleClick { onActivate(favorite.app) }
                .id(favorite.id)
            }
        }
        .padding(.bottom, Theme.Spacing.sm)
    }
}

private struct FavoriteGridCell: View {
    let app: AppEntry
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
            AppIconView(app: app)
                .frame(width: 30, height: 30)
                .overlay(alignment: .bottomTrailing) {
                    if running {
                        Circle()
                            .fill(.secondary)
                            .frame(width: 4, height: 4)
                    }
                }
            Text(app.name)
                .font(Theme.Typography.rowTrailing)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity, minHeight: 64)
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
        .accessibilityLabel(app.name)
    }
}
