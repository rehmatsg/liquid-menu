import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../liquid_menu_platform_interface.dart';
import 'fallback_menu.dart';
import 'ids.dart';
import 'menu.dart';
import 'menu_anchor.dart';
import 'menu_elements.dart';
import 'menu_event.dart';

/// The Dart engine behind the facade — owns ALL state: the current menu
/// session (result completer, action registry, deferred loaders), the event
/// subscription, the memoized handshake, and the platform capability.
final class LiquidMenuEngine {
  LiquidMenuEngine._();

  static final LiquidMenuEngine instance = LiquidMenuEngine._();

  /// Whether the last handshake reported native `UIMenu` support (iOS 17.4+).
  bool get nativeSupported => _nativeSupported;
  bool _nativeSupported = false;

  Future<void>? _handshake;
  _MenuSession? _current;
  StreamSubscription<LiquidMenuEvent>? _eventSub;
  final StreamController<LiquidMenuEvent> _publicEvents =
      StreamController<LiquidMenuEvent>.broadcast();

  /// Lifecycle events for the current menu, re-broadcast for observers.
  Stream<LiquidMenuEvent> get events => _publicEvents.stream;

  /// Whether a native menu session is currently open (presented or
  /// mid-presentation).
  bool get isPresented => _current != null;

  /// Test hook — drops handshake/session state so each test re-handshakes.
  @visibleForTesting
  void resetForTests() {
    _handshake = null;
    _nativeSupported = false;
    _current = null;
    _eventSub?.cancel();
    _eventSub = null;
  }

  /// Test hook — overrides the platform check used to pick the native path.
  /// (Flutter's own `debugDefaultTargetPlatformOverride` trips the test
  /// framework's post-body invariants, so the engine keeps its own.)
  @visibleForTesting
  static TargetPlatform? debugTargetPlatformOverride;

  /// Lazily performs the channel handshake once (native capability detection +
  /// event wiring). Exposed for [LiquidMenus.supportsNativeMenu].
  Future<void> ensureHandshaken() {
    return _handshake ??= () async {
      final platform = LiquidMenuPlatform.instance;
      platform.deferredResolver = _resolveDeferred;
      try {
        final caps = await platform.handshake(MenuIds.session);
        final capsMap = caps['capabilities'];
        _nativeSupported = capsMap is Map && capsMap['nativeMenu'] == true;
      } catch (_) {
        // Channel missing or handshake failed → fallback rendering.
        _nativeSupported = false;
      }
      _eventSub ??= platform.events.listen(_onEvent);
    }();
  }

  /// Presents [menu] at [anchor]. Falls back to the Flutter-rendered menu when
  /// the platform can't present natively (non-iOS, iOS < 17.4, channel loss).
  ///
  /// Completes with the first selected action's `value`, or null when the menu
  /// was dismissed without a selection. Per-action `onSelected` callbacks fire
  /// for every tap — including repeats while `keepsMenuPresented` holds the
  /// menu open.
  Future<Object?> show({
    required BuildContext context,
    required LiquidMenu menu,
    required LiquidMenuAnchor anchor,
  }) async {
    await ensureHandshaken();

    // One menu at a time — a new show supersedes the open one.
    _finishCurrent(null);

    final platformIsIOS =
        (debugTargetPlatformOverride ?? defaultTargetPlatform) == .iOS;
    if (_nativeSupported && platformIsIOS) {
      final session = _prepare(menu);
      // Install before the await: event-channel delivery can beat the method
      // reply — an early `presented`/`dismissed` must still find its session.
      _current = session;
      var accepted = false;
      try {
        accepted = await LiquidMenuPlatform.instance.show(
          session.menuId,
          session.wireMenu,
          anchor.toMap(),
        );
      } catch (_) {
        accepted = false;
      }
      if (accepted) {
        return session.result.future;
      }
      _finishCurrent(null);
    }
    if (!context.mounted) return null;
    return FallbackMenu.show(context, menu, anchor);
  }

  /// Dismisses the presented menu, if any.
  Future<void> dismiss() async {
    _finishCurrent(null);
    try {
      await LiquidMenuPlatform.instance.dismiss();
    } catch (_) {}
  }

  /// Clears the tracked session, completing its result. Does not ask native
  /// to dismiss — callers that need that go through [dismiss].
  void _finishCurrent(Object? value) {
    final session = _current;
    if (session == null) return;
    _current = null;
    if (!session.result.isCompleted) session.result.complete(value);
  }

  void _onEvent(LiquidMenuEvent event) {
    _publicEvents.add(event);
    final session = _current;
    if (session == null || event.menuId != session.menuId) return;
    switch (event) {
      case LiquidMenuActionEvent(:final actionId):
        final action = session.actions[actionId];
        if (action == null) return;
        action.onSelected?.call();
        if (!session.gotSelection) {
          session.gotSelection = true;
          session.selectedValue = action.value;
        }
      case LiquidMenuDismissed():
        _finishCurrent(session.selectedValue);
      case LiquidMenuPresented():
        break;
    }
  }

  /// Builds the wire menu + the registries that let events and deferred
  /// resolutions route back to the right elements.
  _MenuSession _prepare(LiquidMenu menu) {
    final session = _MenuSession(menuId: MenuIds.mint());
    final wireMenu = menu.toMap((e) => _serialize(e, session));
    session.wireMenu = wireMenu;
    return session;
  }

  Map<String, Object?> _serialize(
    LiquidMenuElement element,
    _MenuSession session,
  ) {
    switch (element) {
      case LiquidMenuAction<Object?> action:
        final wireId = action.id ?? MenuIds.mint();
        session.actions[wireId] = action;
        return {...action.toMap(), 'id': wireId};
      case LiquidMenuSection() || LiquidSubmenu():
        final map = element.toMap();
        final menu = map['menu'] as Map<String, Object?>;
        final children = switch (element) {
          LiquidMenuSection s => s.children,
          LiquidSubmenu s => s.children,
          _ => const <LiquidMenuElement>[],
        };
        menu['items'] = [for (final e in children) _serialize(e, session)];
        return map;
      case LiquidMenuDivider():
        return element.toMap();
      case LiquidMenuDeferred deferred:
        final wireId = deferred.id ?? MenuIds.mint();
        session.deferred[wireId] = deferred.loader;
        return {'type': 'deferred', 'id': wireId};
    }
  }

  /// Native → Dart: resolve a deferred element's children at display time.
  Future<List<Object?>?> _resolveDeferred(
    String menuId,
    String deferredId,
  ) async {
    final session = _current;
    if (session == null || session.menuId != menuId) return const [];
    final loader = session.deferred[deferredId];
    if (loader == null) return const [];
    try {
      final children = await loader();
      return [for (final e in children) _serialize(e, session)];
    } catch (_) {
      return const [];
    }
  }
}

final class _MenuSession {
  _MenuSession({required this.menuId});

  final String menuId;
  final Completer<Object?> result = Completer<Object?>();
  final Map<String, LiquidMenuAction<Object?>> actions = {};
  final Map<String, FutureOr<List<LiquidMenuElement>> Function()> deferred = {};
  late Map<String, Object?> wireMenu;

  Object? selectedValue;
  bool gotSelection = false;
}
