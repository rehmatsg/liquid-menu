import 'package:flutter/widgets.dart';

import 'menu.dart';
import 'menu_anchor.dart';
import 'menu_engine.dart';

/// What gesture opens the menu.
enum LiquidMenuTrigger {
  /// A tap anywhere inside the region opens the menu at the tap point (or the
  /// trigger's rect — see [LiquidMenuRegion.anchor]).
  tap,

  /// A long-press opens the menu — context-menu style.
  longPress,
}

/// Where the presented menu anchors.
enum LiquidMenuAnchorMode {
  /// The menu attaches at the exact tap position.
  tapPoint,

  /// The menu attaches to the region's global bounds, pulldown style.
  triggerRect,
}

/// A region that opens a native menu around its child — the "drop it around a
/// VanceButton or VanceInkWell" surface.
///
/// ```dart
/// LiquidMenuRegion(
///   menu: LiquidMenu(children: [...]),
///   child: VanceChip(label: 'For You'),   // visual-only child
/// )
///
/// // Or keep the trigger's own handler in charge (manual mode):
/// LiquidMenuRegion.builder(
///   menu: menu,
///   builder: (context, show) => VanceButton(onPressed: show, label: 'More'),
/// )
/// ```
///
/// With [trigger] set, the region owns the gesture: give the child a null
/// `onTap`/`onPressed` (or use `.builder`) so taps don't double-handle.
final class LiquidMenuRegion extends StatefulWidget {
  const LiquidMenuRegion({
    super.key,
    required this.menu,
    required this.child,
    this.trigger = .tap,
    this.anchor = .tapPoint,
    this.onSelected,
  }) : builder = null;

  /// Manual mode: the builder receives a `show` closure to call from the
  /// child's own handler (`onPressed`, `onTap`, …). The anchor still resolves
  /// from the recorded pointer position or the region's rect.
  const LiquidMenuRegion.builder({
    super.key,
    required this.menu,
    required this.builder,
    this.anchor = .tapPoint,
    this.onSelected,
  }) : trigger = null,
       child = null;

  /// The menu presented when the region triggers.
  final LiquidMenu menu;

  /// The visual trigger — typically a button-styled widget.
  final Widget? child;

  /// Builder form of [child]; receives the `show` closure (manual trigger).
  final Widget Function(BuildContext context, VoidCallback show)? builder;

  /// The opening gesture; null in builder/manual mode.
  final LiquidMenuTrigger? trigger;

  /// Where the menu anchors — at the tap point or the region's rect.
  final LiquidMenuAnchorMode anchor;

  /// Called after the menu closes with the first selected action's `value`
  /// (null on a bare dismissal). Per-action `onSelected` callbacks also fire.
  final void Function(Object? selected)? onSelected;

  @override
  State<LiquidMenuRegion> createState() => _LiquidMenuRegionState();
}

class _LiquidMenuRegionState extends State<LiquidMenuRegion> {
  /// The last pointer-down position — the tap point. `Listener` receives
  /// pointer events without competing in the gesture arena, so a child's own
  /// recognizers are unaffected.
  Offset? _lastPointer;

  void _recordPointer(PointerDownEvent event) {
    _lastPointer = event.position;
  }

  Future<void> _show() async {
    final anchor = switch (widget.anchor) {
      .tapPoint =>
        _lastPointer != null
            ? LiquidMenuAnchor.point(_lastPointer!)
            : _rectAnchor(),
      .triggerRect => _rectAnchor(),
    };
    final selected = await LiquidMenuEngine.instance.show(
      context: context,
      menu: widget.menu,
      anchor: anchor,
    );
    if (mounted) widget.onSelected?.call(selected);
  }

  LiquidMenuAnchor _rectAnchor() {
    final box = context.findRenderObject();
    if (box is RenderBox && box.hasSize) {
      return .rect(box.localToGlobal(.zero) & box.size);
    }
    return .point(_lastPointer ?? .zero);
  }

  @override
  Widget build(BuildContext context) {
    final child = widget.child ?? widget.builder!(context, _show);
    final trigger = widget.trigger;
    return Listener(
      onPointerDown: _recordPointer,
      child: trigger == null
          ? child
          : GestureDetector(
              behavior: .translucent,
              onTap: trigger == .tap ? _show : null,
              onLongPress: trigger == .longPress ? _show : null,
              child: child,
            ),
    );
  }
}
