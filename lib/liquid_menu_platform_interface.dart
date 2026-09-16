import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'liquid_menu_method_channel.dart';
import 'src/menu_event.dart';

/// The platform interface for `liquid_menu`.
///
/// The Dart engine talks only to [instance]; platform implementations
/// (currently the iOS method channel) subclass this.
abstract class LiquidMenuPlatform extends PlatformInterface {
  LiquidMenuPlatform() : super(token: _token);

  static final Object _token = Object();

  static LiquidMenuPlatform _instance = MethodChannelLiquidMenu();

  /// The default instance of [LiquidMenuPlatform] to use.
  static LiquidMenuPlatform get instance => _instance;

  static set instance(LiquidMenuPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Announces a fresh Dart session so native can flush any state left over
  /// from a previous run (e.g. after a hot restart). Returns a capabilities
  /// map — `capabilities.nativeMenu` reports iOS ≥17.4 programmatic support.
  Future<Map<String, Object?>> handshake(String session) {
    throw UnimplementedError('handshake() has not been implemented.');
  }

  /// Presents the menu [menuId] (a serialized `LiquidMenu` wire map) at
  /// [anchor]. Returns whether native accepted it — `false` means the caller
  /// should render the Flutter fallback instead.
  Future<bool> show(
    String menuId,
    Map<String, Object?> menu,
    Map<String, Object?> anchor,
  ) {
    throw UnimplementedError('show() has not been implemented.');
  }

  /// Dismisses the presented menu, if any. Returns whether one was live.
  Future<bool> dismiss() {
    throw UnimplementedError('dismiss() has not been implemented.');
  }

  /// Testing hook: routes `actionId` through the presented menu's action
  /// handler and dismisses. Synthesized touches can't reach the native menu's
  /// window, so integration tests use this to exercise selection.
  Future<void> debugSelect(String actionId) {
    throw UnimplementedError('debugSelect() has not been implemented.');
  }

  /// Broadcast stream of native → Dart lifecycle events (presented,
  /// dismissed, action), routed by menu id on the Dart side.
  Stream<LiquidMenuEvent> get events {
    throw UnimplementedError('events has not been implemented.');
  }

  /// Resolves a deferred element's children at display time — set by the
  /// engine. Only the method-channel implementation uses it (native → Dart
  /// `resolveDeferred` calls); fakes and fallbacks may ignore it.
  ///
  /// Declared as abstract getter+setter (not a field) so implementers can
  /// override it — a field here would be *shadowed*, not overridden.
  Future<List<Object?>?> Function(String menuId, String deferredId)?
  get deferredResolver;
  set deferredResolver(
    Future<List<Object?>?> Function(String menuId, String deferredId)? resolver,
  );
}
