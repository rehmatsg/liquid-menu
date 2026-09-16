// Tap-behavior demo: two persistent triggers — one in the upper half, one in
// the lower half — tapped alternately so the video shows rect-anchored menus
// hanging below and above their triggers. Prints TAP:DONE when the reel ends
// — tool/record_demo.sh keys off that.
// ignore_for_file: avoid_print

import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:liquid_menu/liquid_menu.dart';

void main() {
  runApp(const _TapDemoApp());
}

class _TapDemoApp extends StatefulWidget {
  const _TapDemoApp();

  @override
  State<_TapDemoApp> createState() => _TapDemoAppState();
}

class _TapDemoAppState extends State<_TapDemoApp> {
  final _topKey = GlobalKey();
  final _bottomKey = GlobalKey();
  String? _picked;

  static final _menu = LiquidMenu(children: [
    LiquidMenuAction(
      title: 'For You',
      value: 'for_you',
      state: .on,
      icon: const LiquidMenuSfSymbol('sparkles'),
    ),
    LiquidMenuAction(
      title: 'New Jobs',
      value: 'new_jobs',
      icon: const LiquidMenuSfSymbol('bolt.fill'),
    ),
    const LiquidMenuDivider(),
    LiquidMenuAction(
      title: 'Remote',
      value: 'remote',
      icon: const LiquidMenuSfSymbol('location'),
    ),
  ]);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_run()));
  }

  /// Dispatches a real touch at [position] through the gesture pipeline — the
  /// region's tap recognizer fires exactly as with a finger.
  void _dispatchTap(Offset position) {
    GestureBinding.instance
        .handlePointerEvent(PointerDownEvent(position: position));
    GestureBinding.instance
        .handlePointerEvent(PointerUpEvent(position: position));
  }

  Offset _centerOf(GlobalKey key) {
    final box = key.currentContext!.findRenderObject()! as RenderBox;
    return box.localToGlobal(box.size.center(.zero));
  }

  Future<void> _run() async {
    await Future<void>.delayed(const Duration(seconds: 2));
    final keys = [_topKey, _bottomKey, _topKey, _bottomKey];
    for (var i = 0; i < keys.length; i++) {
      if (!mounted) return;
      print('TAP:tap$i:START');
      // Each tap lands slightly off-center — like a real finger.
      _dispatchTap(_centerOf(keys[i]) +
          Offset((i.isEven ? -6 : 6).toDouble(), (i - 1.5) * 3));
      await Future<void>.delayed(
          Duration(milliseconds: i == keys.length - 1 ? 6000 : 2600));
      await liquidMenus.dismiss();
      await Future<void>.delayed(const Duration(milliseconds: 900));
      print('TAP:tap$i:END');
    }
    print('TAP:DONE');
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: .ltr,
      child: ColoredBox(
        color: const Color(0xFF0F172A),
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: .topLeft,
              end: .bottomRight,
              colors: [Color(0xFF1E293B), Color(0xFF0F172A), Color(0xFF1E1B4B)],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 2),
                _Trigger(
                  label: 'Feed',
                  key: _topKey,
                  onSelected: (v) => setState(() => _picked = v as String?),
                ),
                const Spacer(flex: 2),
                Text(
                  _picked != null ? 'picked: $_picked' : '',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 13,
                    decoration: .none,
                  ),
                ),
                const Spacer(flex: 4),
                _Trigger(
                  label: 'Feed',
                  key: _bottomKey,
                  onSelected: (v) => setState(() => _picked = v as String?),
                ),
                const Spacer(flex: 2),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Trigger extends StatelessWidget {
  const _Trigger({required this.label, required this.onSelected, super.key});

  final String label;
  final void Function(Object?) onSelected;

  @override
  Widget build(BuildContext context) {
    return LiquidMenuRegion(
      menu: _TapDemoAppState._menu,
      onSelected: onSelected,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF6366F1),
          borderRadius: .circular(14),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: .w600,
            decoration: .none,
          ),
        ),
      ),
    );
  }
}
