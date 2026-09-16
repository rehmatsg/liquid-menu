# liquid_menu

Native iOS popup menus for Flutter — a real `UIMenu` presented by UIKit,
anchored at the tap that opened it or to a widget's bounds. Everywhere else,
it falls back to Flutter's `showMenu` behind the same API.

## Install

```yaml
dependencies:
  liquid_menu:
    git:
      url: https://github.com/rehmatsg/liquid_menu
```

iOS requires Flutter's SwiftPM integration
(`flutter config --enable-swift-package-manager`).

## How it works

No platform view sits in the Flutter tree. On show, the plugin installs an
invisible `UIButton` into a non-interactive overlay in the app's window at the
anchor frame, sets `button.menu = <built UIMenu>` +
`showsMenuAsPrimaryAction = true`, then calls `performPrimaryAction()`
(iOS 17.4+) — the public, documented way to present a control's menu
programmatically. UIKit does the rest.

- `presented`/`dismissed`/`action` events round-trip over an event channel.
- Selection resolves the `show` future with the action's `value`.
- iOS < 17.4, Android, and every other platform render the same menu through
  Flutter's `showMenu` — callers don't branch.

## Usage

```dart
import 'package:liquid_menu/liquid_menu.dart';

// Declarative trigger — presents at the tap point by default.
LiquidMenuRegion(
  menu: LiquidMenu(children: [
    LiquidMenuAction(title: 'For You', icon: const LiquidMenuSfSymbol('sparkles')),
    const LiquidMenuDivider(),
    LiquidSubmenu(title: 'Filters', children: [
      LiquidMenuAction(title: 'Remote only', state: .on),
    ]),
  ]),
  onSelected: (value) => debugPrint('$value'),
  child: const Text('tap me'),
)
```

`anchor: .triggerRect` (the default) makes the region a pulldown anchored to
its own bounds — the menu hangs below the trigger (or above it when the
trigger sits in the window's lower half) with a small gap, never covering it.
`anchor: .tapPoint` anchors at the touch instead, context-menu-at-touch
style. `trigger: .longPress` switches the gesture.

Imperative:

```dart
final picked = await liquidMenus.showAt<String>(tap.globalPosition,
    context: context, menu: menu);
// or anchored to a widget's rect:
final picked2 = await liquidMenus.show<String>(context: context, menu: menu);
```

## Elements

| Dart | Native |
|---|---|
| `LiquidMenuAction` | `UIAction` — title, SF Symbol/`Image` icon, `state` checkmarks, `destructive`, `enabled`, `hidden`, `keepsMenuPresented`, `value`, `onSelected` |
| `LiquidMenuSection` | inline `UIMenu` with header title |
| `LiquidSubmenu` | navigable `UIMenu` child |
| `LiquidMenuDivider` | run-boundary → inline sections |
| `LiquidMenuDeferred` | `UIDeferredMenuElement` — `loader` resolves children at display time |

Menus also take `title`, `identifier`, `options` (`singleSelection` for
radio-style sections), and `preferredElementSize` (`.medium`/`.small`).

## Events

```dart
liquidMenus.events.listen((e) { /* presented / dismissed / action */ });
await liquidMenus.dismiss();
liquidMenus.isPresented;
liquidMenus.supportsNativeMenu;
```

## Platform behavior

- **iOS 17.4+** — real `UIMenu` via `performPrimaryAction()` on an invisible
  overlay button. No platform view is ever added to your tree.
- **iOS < 17.4, Android, everything else** — the same `LiquidMenu` renders
  through Flutter's `showMenu` automatically. `liquidMenus.supportsNativeMenu`
  reports which path is live.

## Testing

Synthesized Flutter touches can't reach the context-menu's window, so
integration tests select rows via `liquidMenus.debugSelect(actionId)`, which
runs the same handler a tap would, then dismisses.

## Layout

```
lib/  test/  example/            # the Flutter plugin, at the repo root
ios/liquid_menu/
  Package.swift                  # bridge + core targets
  Sources/liquid_menu/           # method/event channels, wire decoding
  Sources/LiquidMenu/            # UIKit core — no `import Flutter`
  Tests/LiquidMenuTests/         # core unit tests
Package.swift                    # test harness only — runs the Swift tests
                                 # standalone; not an installable product
tool/record_demo.sh              # simulator demo-video recorder
```
