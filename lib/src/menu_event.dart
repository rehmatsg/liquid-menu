/// Lifecycle events of one presented menu, streamed back over the event
/// channel. Strings on the wire: `presented`/`dismissed`/`action`.
sealed class LiquidMenuEvent {
  const LiquidMenuEvent({required this.menuId});

  /// The Dart-minted id of the menu this event belongs to.
  final String menuId;

  static LiquidMenuEvent? fromMap(Map<Object?, Object?> map) {
    final menuId = map['menuId'] as String?;
    if (menuId == null) return null;
    return switch (map['event']) {
      'presented' => LiquidMenuPresented(menuId: menuId),
      'dismissed' => LiquidMenuDismissed(menuId: menuId),
      'action' => LiquidMenuActionEvent(
        menuId: menuId,
        actionId: map['actionId'] as String? ?? '',
      ),
      _ => null,
    };
  }
}

/// The system began presenting the menu.
final class LiquidMenuPresented extends LiquidMenuEvent {
  const LiquidMenuPresented({required super.menuId});
}

/// The menu finished dismissing (selection or cancellation alike).
final class LiquidMenuDismissed extends LiquidMenuEvent {
  const LiquidMenuDismissed({required super.menuId});
}

/// A row was tapped. May fire repeatedly for `keepsMenuPresented` rows.
final class LiquidMenuActionEvent extends LiquidMenuEvent {
  const LiquidMenuActionEvent({required super.menuId, required this.actionId});

  /// The action's wire id (its `id` field, or the engine-minted one).
  final String actionId;
}
