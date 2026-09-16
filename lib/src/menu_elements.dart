import 'dart:async' show FutureOr;

import 'menu_icon.dart';

/// Checkmark state of a menu row (`UIMenuElement.State`).
enum MenuElementState { off, on, mixed }

/// `UIMenu.ElementSize` — the row density hint.
enum MenuElementSize { automatic, small, medium, large }

/// One element in a [LiquidMenu]'s child list.
sealed class LiquidMenuElement {
  const LiquidMenuElement();

  /// Serializes the element's own fields. Ids are minted and children wired by
  /// the engine's serializer — do not emit 'id' or 'items'.
  Map<String, Object?> toMap();
}

/// A tappable menu row (`UIAction`).
final class LiquidMenuAction<T> extends LiquidMenuElement {
  const LiquidMenuAction({
    this.id,
    this.value,
    required this.title,
    this.icon,
    this.state = .off,
    this.destructive = false,
    this.enabled = true,
    this.hidden = false,
    this.keepsMenuPresented = false,
    this.discoverabilityTitle,
    this.onSelected,
  });

  /// Stable identifier. Auto-minted when omitted.
  final String? id;

  /// The value `showLiquidMenu<T>` completes with when this row is selected.
  final T? value;

  final String title;
  final LiquidMenuIcon? icon;

  /// Checkmark shown when [state] is `.on` (or a dash for `.mixed`).
  final MenuElementState state;

  /// Renders the row in the system red destructive color.
  final bool destructive;

  /// Disabled rows render dimmed and cannot be tapped.
  final bool enabled;

  /// Hidden rows are omitted from the menu.
  final bool hidden;

  /// Keeps the menu open after the tap (`UIMenuElement.Attributes.
  /// keepsMenuPresented`) — for multi-toggle menus. [onSelected] still fires
  /// per tap; the show future completes on dismissal.
  final bool keepsMenuPresented;

  /// Secondary text surfaced in keyboard-shortcut UIs; not shown on iOS touch
  /// menus but carried for completeness.
  final String? discoverabilityTitle;

  /// Fires when the row is tapped. For `keepsMenuPresented` rows this can
  /// fire multiple times per presentation.
  final void Function()? onSelected;

  @override
  Map<String, Object?> toMap() => {
    'type': 'action',
    if (id != null) 'id': id,
    'title': title,
    if (icon != null) 'icon': icon!.toMap(),
    if (state != .off) 'state': state.name,
    if (destructive) 'destructive': true,
    if (!enabled) 'disabled': true,
    if (hidden) 'hidden': true,
    if (keepsMenuPresented) 'keepsMenuPresented': true,
    if (discoverabilityTitle != null)
      'discoverabilityTitle': discoverabilityTitle,
  };
}

/// A separator between the surrounding rows — splits the enclosing run into
/// inline sections, which is how UIMenu renders separators.
final class LiquidMenuDivider extends LiquidMenuElement {
  const LiquidMenuDivider();

  @override
  Map<String, Object?> toMap() => const {'type': 'divider'};
}

/// An inline section: its [children] render as one separated group, with
/// [title] as the section header when non-empty.
final class LiquidMenuSection extends LiquidMenuElement {
  const LiquidMenuSection({
    this.title = '',
    this.icon,
    this.children = const [],
    this.singleSelection = false,
    this.palette = false,
    this.preferredElementSize = .automatic,
  });

  final String title;
  final LiquidMenuIcon? icon;
  final List<LiquidMenuElement> children;

  /// Radio semantics — only one child may be `.on` at a time.
  final bool singleSelection;

  /// Renders the section as an icon palette.
  final bool palette;

  final MenuElementSize preferredElementSize;

  @override
  Map<String, Object?> toMap() => {
    'type': 'section',
    'menu': {
      'title': title,
      if (icon != null) 'image': icon!.toMap(),
      'elementSize': preferredElementSize.name,
      'options': {
        if (singleSelection) 'singleSelection': true,
        if (palette) 'palette': true,
      },
    },
  };
}

/// A nested menu — renders as a row that navigates to a subpage.
final class LiquidSubmenu extends LiquidMenuElement {
  const LiquidSubmenu({
    required this.title,
    this.icon,
    this.children = const [],
    this.destructive = false,
    this.singleSelection = false,
    this.preferredElementSize = .automatic,
  });

  final String title;
  final LiquidMenuIcon? icon;
  final List<LiquidMenuElement> children;
  final bool destructive;
  final bool singleSelection;
  final MenuElementSize preferredElementSize;

  @override
  Map<String, Object?> toMap() => {
    'type': 'submenu',
    'menu': {
      'title': title,
      if (icon != null) 'image': icon!.toMap(),
      'elementSize': preferredElementSize.name,
      'options': {
        if (destructive) 'destructive': true,
        if (singleSelection) 'singleSelection': true,
      },
    },
  };
}

/// Rows resolved when the menu opens (`UIDeferredMenuElement`). [loader] runs
/// at display time — keep it fast, the menu waits on it.
final class LiquidMenuDeferred extends LiquidMenuElement {
  const LiquidMenuDeferred({this.id, required this.loader});

  /// Correlates the resolve request; auto-minted when omitted.
  final String? id;
  final FutureOr<List<LiquidMenuElement>> Function() loader;

  @override
  Map<String, Object?> toMap() => {
    'type': 'deferred',
    if (id != null) 'id': id,
  };
}
