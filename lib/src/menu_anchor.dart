import 'dart:ui' show Offset, Rect;

/// Where a presented menu is anchored, in global (window) coordinates.
sealed class LiquidMenuAnchor {
  const LiquidMenuAnchor();

  /// Anchor at a point — typically the tap location. The menu's attachment
  /// point is the position itself.
  const factory LiquidMenuAnchor.point(Offset position) = LiquidMenuPointAnchor;

  /// Anchor to a rect — typically the trigger's global bounds. The system
  /// picks the attachment edge, pulldown style.
  const factory LiquidMenuAnchor.rect(Rect rect) = LiquidMenuRectAnchor;

  Map<String, Object?> toMap();
}

final class LiquidMenuPointAnchor extends LiquidMenuAnchor {
  const LiquidMenuPointAnchor(this.position);

  final Offset position;

  @override
  Map<String, Object?> toMap() => {
    'type': 'point',
    'x': position.dx,
    'y': position.dy,
  };
}

final class LiquidMenuRectAnchor extends LiquidMenuAnchor {
  const LiquidMenuRectAnchor(this.rect);

  final Rect rect;

  @override
  Map<String, Object?> toMap() => {
    'type': 'rect',
    'x': rect.left,
    'y': rect.top,
    'width': rect.width,
    'height': rect.height,
  };
}
