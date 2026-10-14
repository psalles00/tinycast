# PS — keyboard ownership after closing Settings

The launcher activates Tinycast when summoned, preserving the previous application and own window
before activation. Its NSPanel now starts with an activating style rather than nonactivatingPanel.
The style is defined in PSCustomizations/PSPaletteWindowStyle.swift; it is never toggled on an
existing NSPanel, so WindowServer activation flags and AppKit agree from creation.

NSApplication.activate() is asynchronous and not guaranteed to have completed when it returns.
PaletteWindowController's windowDidBecomeKey callback therefore renews the search focus token on
the following main-queue turn, only if the panel is still visible and key. Open palette menus,
control lists and native form editors retain their own input. Previous-app paste and focus
restoration still use the original target captured before activation.

The palette-menu-click harness compiles the real panel constructor and checks its activating
style, in addition to its existing mouse/menu dispatch assertions. UI validation must include
keyboard-only summoning both with Settings open and after the last Settings window closes,
plus repeated hide/summon cycles, because Settings changes the app's activation policy.

Opening an Actions or category/control-list menu transfers key ownership to its child panel.
The parent dismissal delegate preserves both menu types; AppKit's automatic hidesOnDeactivate is
also off so the controller remains the only dismissal authority. Losing focus outside these
owned interactions continues through the ordinary dismissal path.

Physical keyboard testing still reproduced the problem after build 1384. Search focus now resets
before being requested again, with a cancellable SwiftUI task keyed by focusToken. The controller
also renews that token after NSApplication actually becomes active. This avoids retaining a true
FocusState while AppKit has lost the field editor. Menus and form editors keep their existing guards.

PSPaletteFocus unified logs report activation, key ownership, frontmost process ID and responder
class at summon and after settling. They never record queries or keys. Automation can activate its
target before sending input, so a successful automated search cannot replace a physical hotkey test.

On 2026-10-14 Pedro confirmed physical typing without a click on installed build 1390, then
confirmed two more hide/summon cycles after Settings opened and closed. Runtime logs verified
input arriving at an editable field, no menu freeze and Accessibility trusted. The PS installer
now uses a persistent local code-signing certificate; builds 1388 and 1389 had different executable
hashes but the same certificate-bound designated requirement and retained the Accessibility grant.
Input telemetry is bounded to twelve events per key acquisition and records only modifier masks,
field editability and menu state, never characters or key codes. Use Check for Updates - PS and keep
the same signing identity; installing another publisher's signature may require a fresh grant.
