import 'dart:async';

import 'package:liquid_menu/liquid_menu_platform_interface.dart';
import 'package:liquid_menu/src/menu_event.dart';

/// A controllable [LiquidMenuPlatform] for engine/widget tests: records
/// commands, injects events, and fakes capability.
final class FakeLiquidMenuPlatform extends LiquidMenuPlatform {
  /// Whether handshake reports `capabilities.nativeMenu`.
  bool nativeMenu = true;

  /// What `show` returns.
  bool acceptShow = true;

  /// `dismiss` return value.
  bool wasPresented = false;

  String? session;
  int handshakeCalls = 0;
  int dismissCalls = 0;
  final List<
    ({String menuId, Map<String, Object?> menu, Map<String, Object?> anchor})
  >
  shows = [];

  /// Test hook — stands in for the channel's native→Dart deferred resolver.
  @override
  Future<List<Object?>?> Function(String menuId, String deferredId)?
  deferredResolver;

  final _events = StreamController<LiquidMenuEvent>.broadcast();

  void emit(LiquidMenuEvent event) => _events.add(event);

  @override
  Future<Map<String, Object?>> handshake(String session) async {
    this.session = session;
    handshakeCalls++;
    return {
      'capabilities': {'nativeMenu': nativeMenu},
    };
  }

  @override
  Future<bool> show(
    String menuId,
    Map<String, Object?> menu,
    Map<String, Object?> anchor,
  ) async {
    shows.add((menuId: menuId, menu: menu, anchor: anchor));
    wasPresented = acceptShow;
    return acceptShow;
  }

  /// Recorded debugSelect calls.
  final List<String> debugSelects = [];

  @override
  Future<void> debugSelect(String actionId) async {
    debugSelects.add(actionId);
  }

  @override
  Future<bool> dismiss() async {
    dismissCalls++;
    final was = wasPresented;
    wasPresented = false;
    return was;
  }

  @override
  Stream<LiquidMenuEvent> get events => _events.stream;
}
