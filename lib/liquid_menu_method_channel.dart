import 'package:flutter/services.dart';

import 'liquid_menu_platform_interface.dart';
import 'src/menu_event.dart';

/// Method/event-channel implementation of [LiquidMenuPlatform].
///
/// Commands go over the `liquid_menu` [MethodChannel]; native → Dart events
/// arrive on the `liquid_menu/events` broadcast [EventChannel]. The method
/// channel is also used native → Dart for `resolveDeferred` calls (display-time
/// menu content), handled by [deferredResolver].
class MethodChannelLiquidMenu extends LiquidMenuPlatform {
  MethodChannelLiquidMenu() {
    methodChannel.setMethodCallHandler(_handleNativeCall);
  }

  /// Bumped if the wire format changes incompatibly; native rejects mismatches.
  static const int protocolVersion = 1;

  final MethodChannel methodChannel = const MethodChannel('liquid_menu');
  final EventChannel _eventChannel = const EventChannel('liquid_menu/events');

  /// Resolves a deferred element's children at display time. Set by the
  /// engine; returns serialized element maps.
  @override
  Future<List<Object?>?> Function(String menuId, String deferredId)?
  deferredResolver;

  Stream<LiquidMenuEvent>? _events;

  Map<String, Object?> _envelope(Map<String, Object?> body) => {
    'protocolVersion': protocolVersion,
    ...body,
  };

  @override
  Future<Map<String, Object?>> handshake(String session) async {
    final res = await methodChannel.invokeMapMethod<String, Object?>(
      'handshake',
      _envelope({'session': session}),
    );
    return res ?? <String, Object?>{};
  }

  @override
  Future<bool> show(
    String menuId,
    Map<String, Object?> menu,
    Map<String, Object?> anchor,
  ) async {
    final res = await methodChannel.invokeMapMethod<String, Object?>(
      'show',
      _envelope({'menuId': menuId, 'menu': menu, 'anchor': anchor}),
    );
    return (res?['accepted'] as bool?) ?? false;
  }

  @override
  Future<bool> dismiss() async {
    final res = await methodChannel.invokeMapMethod<String, Object?>(
      'dismiss',
      _envelope(const {}),
    );
    return (res?['dismissed'] as bool?) ?? false;
  }

  @override
  Future<void> debugSelect(String actionId) => methodChannel.invokeMethod<void>(
    'debugSelect',
    _envelope({'actionId': actionId}),
  );

  @override
  Stream<LiquidMenuEvent> get events => _events ??= _eventChannel
      .receiveBroadcastStream()
      .map(
        (dynamic e) => e is Map
            ? LiquidMenuEvent.fromMap(e.cast<Object?, Object?>())
            : null,
      )
      .where((e) => e != null)
      .cast<LiquidMenuEvent>();

  Future<dynamic> _handleNativeCall(MethodCall call) async {
    if (call.method == 'resolveDeferred') {
      final args = (call.arguments as Map).cast<String, Object?>();
      final menuId = args['menuId'] as String? ?? '';
      final id = args['id'] as String? ?? '';
      final resolver = deferredResolver;
      if (resolver == null) return const <Object?>[];
      return resolver(menuId, id);
    }
    return null;
  }
}
