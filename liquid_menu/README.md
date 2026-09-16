# liquid_menu

Native iOS popup menus for Flutter — a real `UIMenu` presented by UIKit,
anchored at the tap that opened it or to a widget's bounds. Everywhere else,
it falls back to Flutter's `showMenu` behind the same API.

## Install

```yaml
dependencies:
  liquid_menu:
    git:
      url: https://github.com/rehmatsg/liquid-menu
      path: liquid_menu
```

iOS requires Flutter's SwiftPM integration
(`flutter config --enable-swift-package-manager`).

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

`anchor: .triggerRect` turns the region into a pulldown anchored to its own
bounds; `trigger: .longPress` switches the gesture.

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
