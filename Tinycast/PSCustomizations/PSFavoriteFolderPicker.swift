import SwiftUI

struct PSFavoriteFolderPicker: View {
    let app: AppEntry
    let coordinator: PSFavoritesCoordinator
    @State private var selected: String?

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            Text("Mover \(app.name)").font(Theme.Typography.panelTitle)
            List(selection: $selected) {
                Text("Favoritos sem pasta").tag("root")
                ForEach(coordinator.core.psFavoriteFolders.folders) { folder in
                    Text(folder.name).tag(folder.id.uuidString)
                }
            }
            HStack {
                Button("Cancelar") { coordinator.closeEditor() }.keyboardShortcut(.cancelAction)
                Spacer()
                Button("Mover") {
                    guard let selected else { return }
                    let id = selected == "root" ? nil : UUID(uuidString: selected)
                    guard coordinator.core.psFavoriteFolders.move(app.preferenceKey, to: id) else {
                        coordinator.reportFolderError()
                        return
                    }
                    coordinator.core.palette.selection = 0
                    coordinator.closeEditor()
                }.keyboardShortcut(.defaultAction).disabled(selected == nil)
            }
        }
        .padding(Theme.Spacing.xl)
        .onAppear {
            selected = coordinator.core.psFavoriteFolders.folders.first(where: { $0.members.contains(app.preferenceKey) })?.id.uuidString ?? "root"
        }
    }
}
