# liquid-menu

Native iOS popup menus for Flutter — a real `UIMenu` presented by UIKit,
anchored at the tap that opened it or to a widget's bounds. Everywhere else,
it falls back to Flutter's `showMenu` behind the same API.

The package is [`liquid_menu`](liquid_menu/).

## Why

UIKit's `UIMenu`/`UIAction` gives you pull-down menus with sections,
submenus, checkmarks, destructive styling, and SF Symbols — the same surface
SwiftUI `Menu` produces. On iOS this plugin drives the genuine presentation
path, so behavior (positioning, scrolling, accessibility) matches the OS.

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

## API

```dart
import 'package:liquid_menu/liquid_menu.dart';

final menu = LiquidMenu(children: [
  LiquidMenuAction(
    title: 'For You',
    value: 'for_you',
    icon: const LiquidMenuSfSymbol('sparkles'),
    state: .on,
  ),
  const LiquidMenuDivider(),
  LiquidMenuSection(title: 'More', children: [
    LiquidSubmenu(title: 'Filters', children: [
      LiquidMenuAction(title: 'Remote only', state: .off),
    ]),
  ]),
  LiquidMenuAction(title: 'Reset', destructive: true),
  LiquidMenuDeferred(loader: () async => [/* resolved at display time */]),
]);
```

Anchored to a widget (tap presents at the touch point; `anchor: .triggerRect`
makes a pulldown off the bounds):

```dart
LiquidMenuRegion(
  menu: menu,
  onSelected: (value) {},
  child: MyButton(),
)
```

Or imperative:

```dart
final picked = await liquidMenus.showAt<String>(
  details.globalPosition,
  context: context,
  menu: menu,
);
```

## Platform support

| | Native UIMenu | Fallback (`showMenu`) |
|---|---|---|
| iOS 17.4+ | ✅ | — |
| iOS < 17.4 | — | ✅ (auto) |
| Android / other | — | ✅ |

The handshake advertises `capabilities.nativeMenu`; `liquidMenus.supportsNativeMenu`
lets callers check.

## Testing

`integration_test` note: synthesized Flutter touches can't reach the
context-menu's window, so drive selection with `liquidMenus.debugSelect(id)`
— it invokes the same handler a real tap does, then dismisses.

## Layout

```
liquid_menu/                      # the Flutter plugin — the whole package
  lib/  test/  example/
  ios/liquid_menu/
    Package.swift                 # bridge + core targets
    Sources/liquid_menu/          # method/event channels, wire decoding
    Sources/LiquidMenu/           # UIKit core — no `import Flutter`
    Tests/LiquidMenuTests/        # core unit tests
Package.swift                     # test harness only — runs the Swift tests
                                  # standalone; not an installable product
```
