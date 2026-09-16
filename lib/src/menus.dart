import 'dart:async';

import 'package:flutter/widgets.dart';

import 'menu.dart';
import 'menu_anchor.dart';
import 'menu_engine.dart';
import '../liquid_menu_platform_interface.dart';
import 'menu_event.dart';

/// The package's facade — a callable singleton like liquid_toasts' `toast`:
///
/// ```dart
/// final picked = await liquidMenus.show(context: context, menu: menu);
/// ```
const LiquidMenus liquidMenus = LiquidMenus.instance;

/// Presents a native `UIMenu` on iOS 17.4+ (falling back to a Flutter
/// `showMenu` everywhere else), anchored to [context]'s render box or to an
/// explicit [anchor].
///
/// Completes with the first selected action's `value`, or null when the menu
/// is dismissed without a selection. Per-action `onSelected` callbacks fire
/// for every tap — including repeats while a `keepsMenuPresented` row holds
/// the menu open.
final class LiquidMenus {
  const LiquidMenus._();

  static const LiquidMenus instance = LiquidMenus._();

  /// Shows [menu] anchored to [context]'s render box. Pass an explicit
  /// [anchor] (e.g. `LiquidMenuAnchor.point(details.globalPosition)` from an
  /// `onTapDown`) to anchor at the touch itself.
  Future<T?> show<T>({
    required BuildContext context,
    required LiquidMenu menu,
    LiquidMenuAnchor? anchor,
  }) async {
    final resolved = anchor ?? _rectOf(context);
    final result = await LiquidMenuEngine.instance.show(
      context: context,
      menu: menu,
      anchor: resolved,
    );
    return result as T?;
  }

  /// Shows [menu] anchored at a global position — e.g. the tap location.
  Future<T?> showAt<T>(
    Offset position, {
    required BuildContext context,
    required LiquidMenu menu,
  }) => show<T>(context: context, menu: menu, anchor: .point(position));

  /// Dismisses the presented menu, if any.
  Future<void> dismiss() => LiquidMenuEngine.instance.dismiss();

  /// Testing hook: routes [actionId] through the presented native menu's
  /// action handler and dismisses — what a real row tap does end-to-end.
  /// Synthesized test touches can't reach the menu's window, so
  /// `integration_test` suites drive selection through this.
  @visibleForTesting
  Future<void> debugSelect(String actionId) =>
      LiquidMenuPlatform.instance.debugSelect(actionId);

  /// Lifecycle events (presented / dismissed / action) for the current menu.
  Stream<LiquidMenuEvent> get events => LiquidMenuEngine.instance.events;

  /// Whether a native menu session is currently open.
  bool get isPresented => LiquidMenuEngine.instance.isPresented;

  /// Whether this device can present native `UIMenu`s (iOS 17.4+). Known after
  /// the first handshake — lazily triggered by the first `show`.
  Future<bool> get supportsNativeMenu async {
    await LiquidMenuEngine.instance.ensureHandshaken();
    return LiquidMenuEngine.instance.nativeSupported;
  }

  /// The context's global bounds — the trigger rect.
  static LiquidMenuAnchor _rectOf(BuildContext context) {
    final box = context.findRenderObject();
    if (box is RenderBox && box.hasSize) {
      return .rect(box.localToGlobal(.zero) & box.size);
    }
    // Not laid out (or not a box) — fall back to the screen center so the
    // menu still presents somewhere sensible.
    final size = MediaQuery.maybeSizeOf(context) ?? .zero;
    return .point(size.center(.zero));
  }
}
