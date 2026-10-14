import AppKit

/// The launcher explicitly activates Tinycast. A non-activating panel uses a different
/// WindowServer keyboard handoff and can retain a phantom key state after Settings closes.
@MainActor
enum PSPaletteWindowStyle {
    static let styleMask: NSWindow.StyleMask = [.borderless, .fullSizeContentView]
}
