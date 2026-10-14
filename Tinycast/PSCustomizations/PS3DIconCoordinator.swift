import AppKit
import Observation

@MainActor @Observable
final class PS3DIconCoordinator {
    static let root = URL(fileURLWithPath: "/Volumes/PS-Externo/Themes/3D Icons", isDirectory: true)
    private(set) var entries: [PS3DIcon] = []
    private(set) var errorMessage: String?
    private(set) var loading = false
    @ObservationIgnored unowned let core: AppCore
    @ObservationIgnored let windowController: PaletteWindowController

    init(core: AppCore, windowController: PaletteWindowController) {
        self.core = core
        self.windowController = windowController
    }

    func load() async {
        guard !loading else { return }
        loading = true
        defer { loading = false }
        do {
            entries = try await PS3DIconCatalog.load(root: Self.root)
            cachedQuery = nil
            errorMessage = nil
        } catch {
            entries = []
            cachedQuery = nil
            errorMessage = "Catálogo 3D indisponível. Conecte o PS-Externo e tente novamente."
        }
    }

    @ObservationIgnored private var cachedQuery: String?
    @ObservationIgnored private var cachedMatches: [PS3DIcon] = []

    func matches(query: String) -> [PS3DIcon] {
        let entries = entries
        if cachedQuery != query {
            cachedMatches = PS3DIconCatalog.search(entries, query: query)
            cachedQuery = query
        }
        return cachedMatches
    }

    func deliver(_ icon: PS3DIcon, size: Int = 128, paste: Bool = true, keepOpen: Bool = false) {
        let url = icon.url(root: Self.root, size: size)
        let target = windowController.previousApp
        let query = core.palette.query
        let filter = core.palette.emojiCategoryFilter
        let selection = core.palette.selection
        Task {
            guard let data = await Self.imageData(url), NSImage(data: data) != nil else {
                core.showMessage("Imagem 3D indisponível em \(size) px.", tone: .danger)
                return
            }
            guard core.paletteCoordinator.isVisible, core.palette.mode == .emoji,
                core.palette.selection == selection, core.palette.query == query,
                core.palette.emojiCategoryFilter == filter
            else { return }
            let pb = NSPasteboard.general
            pb.clearContents()
            pb.declareTypes([.png, ClipboardManager.internalType], owner: nil)
            pb.setData(data, forType: .png)
            pb.setData(Data(), forType: ClipboardManager.internalType)
            if !keepOpen { core.paletteCoordinator.hidePalette(restoreFocus: false) }
            guard paste, target != nil else { return }
            if keepOpen {
                guard let pid = target?.processIdentifier else { return }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { Paster.postCommandV(toPid: pid) }
            } else {
                target?.activate()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) { Paster.postCommandV() }
            }
        }
    }

    @concurrent static func imageData(_ url: URL) async -> Data? {
        try? Data(contentsOf: url, options: .mappedIfSafe)
    }

    func actions(_ icon: PS3DIcon) -> PopoverMenuContent {
        var items = [
            PopoverMenuItem(title: "Colar ícone 3D · 128 px", systemImage: "doc.on.clipboard", shortcut: "↵")
            { self.deliver(icon) },
            PopoverMenuItem(title: "Copiar ícone 3D · 128 px", systemImage: "doc.on.doc", shortcut: "⌘↵") {
                self.deliver(icon, paste: false)
            },
            PopoverMenuItem(title: "Colar e manter janela aberta", systemImage: "macwindow", shortcut: "⌥↵") {
                self.deliver(icon, keepOpen: true)
            }
        ]
        for size in [256, 512, 1024] {
            items.append(
                PopoverMenuItem(
                    title: "Colar · \(size) px", systemImage: "doc.on.clipboard", startsSection: size == 256
                ) { self.deliver(icon, size: size) })
            items.append(
                PopoverMenuItem(title: "Copiar · \(size) px", systemImage: "doc.on.doc") {
                    self.deliver(icon, size: size, paste: false)
                })
        }
        items.append(
            PopoverMenuItem(title: "Copiar caminho do arquivo", systemImage: "link", startsSection: true) {
                Paster.copyString(icon.url(root: Self.root).path)
            })
        return PopoverMenuContent(header: icon.title, items: items)
    }
}
