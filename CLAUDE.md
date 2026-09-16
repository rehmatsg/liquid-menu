# CLAUDE.md

## What this is

A Flutter plugin (repo root) presenting native iOS `UIMenu` popups,
with a Flutter `showMenu` fallback on non-iOS and iOS < 17.4. The iOS
implementation is a thin UIKit wrapper — `MenuSpec` → `UIMenu`, an overlay
host, and a presenter — all inside the plugin's Swift package.

The plugin's iOS package (`ios/liquid_menu/`) carries two targets:
the bridge (`Sources/liquid_menu/` — channels + wire decoding, the only
`import Flutter` code) and the core (`Sources/LiquidMenu/` — Flutter-free
UIKit).

**The plugin's iOS manifest must never name a path above its own directory.**
Flutter symlinks the package into the consuming app's
`ios/Flutter/ephemeral/Packages/.packages/liquid_menu`, and SwiftPM resolves
manifest paths against that symlink — a `path:` reaching for the repo root
lands in the app's ephemeral folder and fails resolution.

The **repo-root `Package.swift` is a test harness, not a product**: it
re-declares the `LiquidMenu` target (path into the plugin dir) plus the test
target so the core compiles and tests standalone. The plugin manifest itself
can't resolve without a Flutter app (its `FlutterFramework` path dependency
only exists inside one).

## Commands

Dart commands run from the repo root; the app from `example/`.

```bash
flutter analyze
flutter test

# Swift core tests via the root manifest (auto scheme is named after the
# package, not a product):
xcodebuild test -scheme liquid_menu-Package -destination 'platform=iOS Simulator,name=iPhone 17'

# On-device e2e (presents a real UIMenu, verifies the event round-trip):
cd example && flutter test integration_test -d <simulator-id>
```

The plugin is SwiftPM-only — consumers need
`flutter config --enable-swift-package-manager`.

## Architecture

- **Core** (`LiquidMenu`, Flutter-free): `MenuModels` (spec/anchor/elements),
  `MenuBuilder` (`MenuSpec` → `UIMenu`/`UIAction`; contiguous runs between
  dividers/sections become `.displayInline` sections), `MenuOverlayHost`
  (singleton overlay view in the app window), `MenuAnchorControl` (invisible
  `UIButton`; `menu` + `showsMenuAsPrimaryAction`), `MenuPresenter`
  (one-menu-at-a-time, generation counter, per-presentation state box,
  performPrimaryAction on a deferred runloop tick, 500ms presentation
  watchdog).
- **Bridge** (`liquid_menu`, the only Flutter-aware target):
  `LiquidMenuPlugin.swift` (method routing on `MainActor`, event channel),
  `WireModels.swift` (`init?(wire:)` decoders → core models),
  `WireDecoding.swift` (NSNumber-aware `[String: Any]` helpers).
- **Dart**: `LiquidMenuEngine` (internal singleton) owns sessions — action
  registry by wire id, deferred resolvers, the result `Completer`, event
  routing, the memoized handshake (`nativeMenu` capability gates native vs
  fallback). `liquidMenus` (`src/menus.dart`) is the public facade;
  `LiquidMenuRegion` wraps a child with tap/long-press triggers;
  `FallbackMenu` renders the same spec via `showMenu`.

### Wire invariants

- Enum/event strings match exactly across the channel (`presented`/`dismissed`/
  `action`; element `type`s; symbol rendering mode `automatic`).
- Ids are minted in Dart (`lm_<n>`); a `handshake` carries a random session
  prefix. Native flushes pending menus on every handshake (hot restart).
- `show` acks `{accepted}`; `dismiss` acks `{dismissed}`; `debugSelect` is a
  test hook invoking the live action handler (synthesized touches can't reach
  the context-menu window).
- Nested actions (inside sections/submenus) must register in the session's
  action map or their events can't route.

### Presentation notes

- `performPrimaryAction()` is iOS 17.4+. The control MUST be a `UIButton`
  with `.menu` set — a bare `UIControl` with a context-menu-config override
  crashes (`UITargetedPreview`: view-not-in-window) and must not be revived.
- The anchor button lives in a non-interactive overlay; `performPrimaryAction`
  is deferred one runloop so the interaction can install.
- iOS < 17.4 reports `nativeMenu: false` and Dart falls back automatically.
