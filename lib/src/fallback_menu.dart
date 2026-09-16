import 'dart:async';

import 'package:flutter/material.dart';

import 'menu.dart';
import 'menu_anchor.dart';
import 'menu_elements.dart';
import 'menu_icon.dart';

/// The non-native path: renders the same [LiquidMenu] model with Flutter's
/// `showMenu`. Used on non-iOS platforms and on iOS < 17.4, where programmatic
/// `UIMenu` presentation is unavailable.
///
/// Approximations vs. the native surface: submenus open a second popup after
/// the first closes; `keepsMenuPresented` rows still dismiss the menu;
/// sections render as a divider plus an optional header row; `.mixed` state
/// shows a checkmark like `.on`.
final class FallbackMenu {
  FallbackMenu._();

  static Future<Object?> show(
    BuildContext context,
    LiquidMenu menu,
    LiquidMenuAnchor anchor,
  ) {
    return _present(context, menu, _position(context, anchor));
  }

  static RelativeRect _position(BuildContext context, LiquidMenuAnchor anchor) {
    final overlay = Overlay.of(context).context.findRenderObject();
    final overlaySize = overlay is RenderBox
        ? overlay.size
        : MediaQuery.sizeOf(context);
    final rect = switch (anchor) {
      LiquidMenuPointAnchor(:final position) => Rect.fromLTWH(
        position.dx,
        position.dy,
        0,
        0,
      ),
      LiquidMenuRectAnchor(:final rect) => rect,
    };
    return RelativeRect.fromRect(rect, Offset.zero & overlaySize);
  }

  static Future<Object?> _present(
    BuildContext context,
    LiquidMenu menu,
    RelativeRect position,
  ) async {
    final items = await _entries(context, menu.children);
    if (items.isEmpty) return null;
    if (!context.mounted) return null;
    final selected = await showMenu<Object?>(
      context: context,
      position: position,
      items: items,
    );
    switch (selected) {
      case _SubmenuJump(:final submenu):
        if (!context.mounted) return null;
        return _present(
          context,
          LiquidMenu(children: submenu.children),
          position,
        );
      case LiquidMenuAction<Object?> action:
        action.onSelected?.call();
        return action.value;
      default:
        return null;
    }
  }

  static Future<List<PopupMenuEntry<Object?>>> _entries(
    BuildContext context,
    List<LiquidMenuElement> children,
  ) {
    return _entriesWithTheme(Theme.of(context), children);
  }

  static Future<List<PopupMenuEntry<Object?>>> _entriesWithTheme(
    ThemeData theme,
    List<LiquidMenuElement> children,
  ) async {
    final entries = <PopupMenuEntry<Object?>>[];
    for (final element in children) {
      switch (element) {
        case LiquidMenuAction<Object?> action:
          if (action.hidden) break;
          entries.add(_actionEntry(theme, action));
        case LiquidMenuDivider():
          if (entries.isNotEmpty) entries.add(const PopupMenuDivider());
        case LiquidMenuSection section:
          if (entries.isNotEmpty) entries.add(const PopupMenuDivider());
          if (section.title.isNotEmpty) {
            entries.add(_headerEntry(theme, section.title));
          }
          entries.addAll(await _entriesWithTheme(theme, section.children));
        case LiquidSubmenu submenu:
          entries.add(_submenuEntry(theme, submenu));
        case LiquidMenuDeferred deferred:
          try {
            final resolved = await deferred.loader();
            entries.addAll(await _entriesWithTheme(theme, resolved));
          } catch (_) {}
      }
    }
    return entries;
  }

  static PopupMenuEntry<Object?> _actionEntry(
    ThemeData theme,
    LiquidMenuAction<Object?> action,
  ) {
    final color = action.destructive ? theme.colorScheme.error : null;
    return PopupMenuItem<Object?>(
      value: action,
      enabled: action.enabled,
      child: Row(
        children: [
          if (action.icon != null) ...[
            _FallbackIcon(icon: action.icon!, color: color),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Text(action.title, style: TextStyle(color: color)),
          ),
          if (action.state != .off) ...[
            const SizedBox(width: 12),
            Icon(Icons.check, size: 18, color: color),
          ],
        ],
      ),
    );
  }

  static PopupMenuEntry<Object?> _headerEntry(ThemeData theme, String title) {
    return PopupMenuItem<Object?>(
      enabled: false,
      height: 28,
      child: Text(title, style: theme.textTheme.labelSmall),
    );
  }

  static PopupMenuEntry<Object?> _submenuEntry(
    ThemeData theme,
    LiquidSubmenu submenu,
  ) {
    return PopupMenuItem<Object?>(
      value: _SubmenuJump(submenu),
      child: Row(
        children: [
          if (submenu.icon != null) ...[
            _FallbackIcon(icon: submenu.icon!),
            const SizedBox(width: 12),
          ],
          Expanded(child: Text(submenu.title)),
          const Icon(Icons.chevron_right, size: 18),
        ],
      ),
    );
  }
}

/// Marker: the selected row opens a submenu (a second popup).
final class _SubmenuJump {
  const _SubmenuJump(this.submenu);
  final LiquidSubmenu submenu;
}

/// Best-effort fallback icon: SF Symbols render as a generic glyph dot —
/// `LiquidMenuImage` bytes render as the actual bitmap.
final class _FallbackIcon extends StatelessWidget {
  const _FallbackIcon({required this.icon, this.color});

  final LiquidMenuIcon icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return switch (icon) {
      LiquidMenuSfSymbol() => Icon(Icons.circle, size: 14, color: color),
      LiquidMenuImage(:final bytes) => Image.memory(
        bytes,
        width: 18,
        height: 18,
        color: color,
      ),
    };
  }
}
