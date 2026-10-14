# PS — merged emoji, symbols and 3D icon picker

The existing Search Emoji command retains its identity and shortcuts, with a new visible title:
Search Emoji, Symbols & 3D Icons. All Categories merges emoji results with a titled 3D section;
the category menu also offers 3D Icons alone. Emoji pins, recent usage, skin tones and zoom retain
their original behavior. Images never become fake Unicode entries or emoji usage records.

The implementation lives in PSCustomizations: PS3DIconCatalog reads metadata and normalizes
Portuguese search terms; PS3DIconCoordinator owns the catalog and image delivery; PSEmojiIconGridView
preserves row-level interaction, lazy rows and section-namespaced keyboard scroll targets.
AppCore owns the coordinator. Hooks in EmojiScreen, EmojiCategoryFilter and EmojiGrid join the
section model; CommandID changes only the title. XcodeGen owns project registration.

The read-only source is /Volumes/PS-Externo/Themes/3D Icons. Metadata prefers size-128/meta.pt-br.json,
otherwise meta.json. Existing generated PNGs and their saved descriptions also enter search.
Every query searches the whole catalog, showing the first 100 matches with a refinement hint when
more match. Metadata and image reads run off the main actor; thumbnails are loaded only for visible
rows. Each picker opening reloads metadata, so newly saved icons appear without restarting Tinycast.
A missing disk/catalog produces an inline message in the 3D category. No catalog files are modified.

Enter pastes a 128px PNG; Command-Enter copies it; Option-Enter pastes while keeping the window open.
Command-K offers paste/copy in 128, 256, 512 and 1024px and copying the absolute path. Missing images
leave the clipboard untouched. Asynchronous reads validate the screen, selection, query and filter
before delivery. The standard paste machinery retains its existing accessibility permission flow.
AI generation remains in the original plugin/app; this integration reads its existing outputs.

Tests: ps-icons-test exercises Portuguese terms, multiword search, generated descriptions, rejection
of filename traversal, resolution paths, read-only metadata and navigation across mixed sections.
The upstream emoji category-count assertion includes the new category. The existing form-input
pixel harness fixes dark appearance on its own window because its detector expects white ink;
this does not change the user's appearance or application rendering.
