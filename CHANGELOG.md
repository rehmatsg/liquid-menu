## 0.1.0

- Initial release: native iOS `UIMenu` popup menus for Flutter.
- `LiquidMenuRegion` (tap / long-press, point or rect anchor), imperative
  `liquidMenus.showAt` / `show`, and a Flutter `showMenu` fallback on
  non-iOS platforms and iOS < 17.4.
- Actions with values/callbacks, icons (SF Symbol + image), checkmark states,
  destructive/disabled/hidden rows, sections, submenus, and deferred items.
- Lifecycle events (`presented`/`dismissed`/`action`), `isPresented`,
  `dismiss()`, and the `debugSelect` integration-test hook.
