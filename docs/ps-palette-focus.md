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
