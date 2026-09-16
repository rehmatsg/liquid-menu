# CLAUDE.md

## What this is

A monorepo shipping two packages built from one UIKit implementation:

- **`LiquidMenu`** — a standalone Swift package for native iOS apps. Sources at
  `liquid-menu-swift/Sources/LiquidMenu/`; its manifest is the repo-root
  `Package.swift` (SwiftPM only resolves a git URL whose repo root holds a
  manifest, so the root one is thin and points at that folder via `path:`).
- **`liquid_menu`** (`liquid_menu/`) — the Flutter plugin: a Dart facade over
  the native presenter via method/event channels, with a Flutter `showMenu`
  fallback on non-iOS and iOS < 17.4. The plugin's Swift package carries two
  targets: the bridge (`Sources/liquid_menu/`) and the `LiquidMenu` core,
  reached by a **symlink** at `Sources/LiquidMenu` → the core folder.

**The plugin's iOS manifest must never name a path above its own directory.**
Flutter symlinks the package into the consuming app's
`ios/Flutter/ephemeral/Packages/.packages/liquid_menu`, and SwiftPM resolves
manifest paths against that symlink — a `path:` reaching for the repo root
lands in the app's ephemeral folder and fails resolution. The source symlink
is safe where a manifest path is not: the filesystem follows it from its own
real location.

## Commands

Dart commands run from `liquid_menu/`; the app from `liquid_menu/example/`.

```bash
cd liquid_menu
flutter analyze
flutter test

# Swift core (iOS-only; use the root package's auto scheme, named after the
# package not the product):
xcodebuild test -scheme liquid-menu -destination 'platform=iOS Simulator,name=iPhone 17'

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
