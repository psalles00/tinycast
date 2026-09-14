import AppKit
import SwiftUI

/// PS-only overlay that claims the physical middle mouse button without disturbing normal clicks.
struct MiddleClickCatcher: NSViewRepresentable {
    let action: () -> Void

    func makeNSView(context: Context) -> NSView { CatcherView(action: action) }

    func updateNSView(_ nsView: NSView, context: Context) {
        (nsView as? CatcherView)?.action = action
    }

    private final class CatcherView: NSView {
        var action: () -> Void

        init(action: @escaping () -> Void) {
            self.action = action
            super.init(frame: .zero)
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) { fatalError() }

        override func otherMouseDown(with event: NSEvent) {
            guard event.buttonNumber == 2 else { return }
            action()
        }

        override func hitTest(_ point: NSPoint) -> NSView? {
            guard let event = NSApp.currentEvent,
                event.buttonNumber == 2,
                [.otherMouseDown, .otherMouseUp, .otherMouseDragged].contains(event.type)
            else { return nil }
            return super.hitTest(point)
        }
    }
}

extension View {
    func onMiddleClick(perform action: @escaping () -> Void) -> some View {
        overlay(MiddleClickCatcher(action: action))
    }
}
