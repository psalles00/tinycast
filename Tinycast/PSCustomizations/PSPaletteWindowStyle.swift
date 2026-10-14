import AppKit
import ApplicationServices
import OSLog

/// The launcher explicitly activates Tinycast. A non-activating panel uses a different
/// WindowServer keyboard handoff and can retain a phantom key state after Settings closes.
@MainActor
enum PSPaletteWindowStyle {
    static let styleMask: NSWindow.StyleMask = [.borderless, .fullSizeContentView]

    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.tinycast.app", category: "PSPaletteFocus")

    static func recordFocus(_ panel: NSPanel, phase: String) {
        let frontmost = NSWorkspace.shared.frontmostApplication?.processIdentifier ?? -1
        let responder = panel.firstResponder.map { String(describing: type(of: $0)) } ?? "nil"
        logger.info("""
            \(phase, privacy: .public): active=\(NSApp.isActive) key=\(panel.isKeyWindow) \
            frontPID=\(frontmost) responder=\(responder, privacy: .public)
            accessibility=\(AXIsProcessTrusted())
            """)
    }

    static func recordInput(_ panel: NSPanel, modifiers: UInt, menuOpen: Bool) {
        let editable = (panel.firstResponder as? NSTextView)?.isEditable ?? false
        logger.info("input: modifiers=\(modifiers) editable=\(editable) menuOpen=\(menuOpen)")
    }
}
