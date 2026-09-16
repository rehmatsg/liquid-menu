import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_menu/liquid_menu.dart';
import 'package:liquid_menu/liquid_menu_platform_interface.dart';
import 'package:liquid_menu/src/menu_engine.dart';

import 'fake_platform.dart';

void main() {
  late FakeLiquidMenuPlatform platform;
  late BuildContext context;

  Future<Object?> show(LiquidMenu menu, {LiquidMenuAnchor? anchor}) {
    return LiquidMenuEngine.instance.show(
      context: context,
      menu: menu,
      anchor: anchor ?? const LiquidMenuPointAnchor(Offset(100, 200)),
    );
  }

  setUp(() {
    platform = FakeLiquidMenuPlatform();
    LiquidMenuPlatform.instance = platform;
    LiquidMenuEngine.instance.resetForTests();
    LiquidMenuEngine.debugTargetPlatformOverride = .iOS;
  });

  tearDown(() {
    LiquidMenuEngine.debugTargetPlatformOverride = null;
  });

  Future<void> mount(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (ctx) {
            context = ctx;
            return const SizedBox();
          },
        ),
      ),
    );
  }

  group('wire serialization', () {
    testWidgets('action serializes static fields and a minted id', (t) async {
      await mount(t);
      final menu = LiquidMenu(
        children: [
          LiquidMenuAction(
            title: 'Delete',
            icon: const LiquidMenuSfSymbol('trash'),
            destructive: true,
            enabled: false,
            hidden: true,
            keepsMenuPresented: true,
            discoverabilityTitle: 'Del',
            state: .mixed,
          ),
        ],
      );
      unawaited(show(menu));
      await t.pump();
      final items = platform.shows.single.menu['items'] as List;
      expect(items.single, {
        'type': 'action',
        'id': startsWith('lm_'),
        'title': 'Delete',
        'icon': {'kind': 'sfSymbol', 'name': 'trash'},
        'state': 'mixed',
        'destructive': true,
        'disabled': true,
        'hidden': true,
        'keepsMenuPresented': true,
        'discoverabilityTitle': 'Del',
      });
    });

    testWidgets('explicit action id is preserved on the wire', (t) async {
      await mount(t);
      unawaited(
        show(
          LiquidMenu(
            children: [LiquidMenuAction(id: 'save', title: 'Save')],
          ),
        ),
      );
      await t.pump();
      final items = platform.shows.single.menu['items'] as List;
      expect((items.single as Map)['id'], 'save');
    });

    testWidgets('divider, section and submenu shapes', (t) async {
      await mount(t);
      final menu = LiquidMenu(
        children: [
          LiquidMenuAction(title: 'A'),
          const LiquidMenuDivider(),
          LiquidMenuSection(
            title: 'Group',
            singleSelection: true,
            children: [LiquidMenuAction(title: 'B', state: .on)],
          ),
          LiquidSubmenu(
            title: 'More',
            icon: const LiquidMenuSfSymbol('ellipsis'),
            children: [LiquidMenuAction(title: 'C')],
          ),
        ],
      );
      unawaited(show(menu));
      await t.pump();
      final items = platform.shows.single.menu['items'] as List;
      expect(items[1], {'type': 'divider'});
      expect(items[2]['type'], 'section');
      expect(items[2]['menu']['options'], {'singleSelection': true});
      expect(items[2]['menu']['items'].single['state'], 'on');
      expect(items[3]['type'], 'submenu');
      expect(items[3]['menu']['title'], 'More');
      expect(items[3]['menu']['image'], {
        'kind': 'sfSymbol',
        'name': 'ellipsis',
      });
      expect(items[3]['menu']['items'].single['title'], 'C');
    });

    testWidgets('nested actions inside sections join the registry', (t) async {
      await mount(t);
      var fired = false;
      final menu = LiquidMenu(
        children: [
          LiquidMenuSection(
            children: [
              LiquidMenuAction(title: 'Nested', onSelected: () => fired = true),
            ],
          ),
        ],
      );
      final future = show(menu);
      await t.pump();
      final menuId = platform.shows.single.menuId;
      final items = platform.shows.single.menu['items'] as List;
      final nestedId =
          (items.single['menu']['items'].single as Map)['id'] as String;
      expect(nestedId, startsWith('lm_'));
      platform.emit(LiquidMenuActionEvent(menuId: menuId, actionId: nestedId));
      await t.pump();
      expect(fired, isTrue);
      platform.emit(LiquidMenuDismissed(menuId: menuId));
      await future;
    });

    testWidgets('deferred mints an id and registers its loader', (t) async {
      await mount(t);
      unawaited(
        show(
          LiquidMenu(
            children: [
              LiquidMenuDeferred(
                loader: () async => [LiquidMenuAction(title: 'Late')],
              ),
            ],
          ),
        ),
      );
      await t.pump();
      final items = platform.shows.single.menu['items'] as List;
      expect(items.single['type'], 'deferred');
      expect(items.single['id'], startsWith('lm_'));

      final resolved = await platform.deferredResolver!(
        platform.shows.single.menuId,
        items.single['id'] as String,
      );
      expect(resolved!.single, isA<Map>());
      expect((resolved.single as Map)['title'], 'Late');
    });

    testWidgets('anchor maps', (t) async {
      await mount(t);
      unawaited(
        show(
          const LiquidMenu(children: []),
          anchor: const .point(Offset(10, 20)),
        ),
      );
      await t.pump();
      expect(platform.shows.single.anchor, {
        'type': 'point',
        'x': 10.0,
        'y': 20.0,
      });

      unawaited(
        show(
          const LiquidMenu(children: []),
          anchor: const .rect(Rect.fromLTWH(1, 2, 30, 40)),
        ),
      );
      await t.pump();
      expect(platform.shows.last.anchor, {
        'type': 'rect',
        'x': 1.0,
        'y': 2.0,
        'width': 30.0,
        'height': 40.0,
      });
    });

    testWidgets(
      'sf symbol icon serializes weight/scale/renderingMode/palette',
      (t) async {
        await mount(t);
        unawaited(
          show(
            LiquidMenu(
              children: [
                LiquidMenuAction(
                  title: 'A',
                  icon: const LiquidMenuSfSymbol(
                    'star.fill',
                    weight: .bold,
                    scale: .large,
                    renderingMode: .palette,
                    palette: [Color(0xFFFF0000), Color(0xFF00FF00)],
                  ),
                ),
              ],
            ),
          ),
        );
        await t.pump();
        final items = platform.shows.single.menu['items'] as List;
        expect(items.single['icon'], {
          'kind': 'sfSymbol',
          'name': 'star.fill',
          'weight': 'bold',
          'scale': 'large',
          'renderingMode': 'palette',
          'palette': [0xFFFF0000, 0xFF00FF00],
        });
      },
    );
  });

  group('session lifecycle', () {
    testWidgets('show completes with the selected action value on dismiss', (
      t,
    ) async {
      await mount(t);
      final menu = LiquidMenu(
        children: [
          LiquidMenuAction(title: 'One', value: 'one'),
          LiquidMenuAction(title: 'Two', value: 'two'),
        ],
      );
      final result = show(menu);
      await t.pump();
      final menuId = platform.shows.single.menuId;
      final items = platform.shows.single.menu['items'] as List;
      final secondId = (items.last as Map)['id'] as String;

      platform.emit(LiquidMenuActionEvent(menuId: menuId, actionId: secondId));
      platform.emit(LiquidMenuDismissed(menuId: menuId));
      expect(await result, 'two');
    });

    testWidgets('bare dismissal completes null', (t) async {
      await mount(t);
      final result = show(const LiquidMenu(children: []));
      await t.pump();
      platform.emit(LiquidMenuDismissed(menuId: platform.shows.single.menuId));
      expect(await result, isNull);
    });

    testWidgets('events for a stale menuId are ignored', (t) async {
      await mount(t);
      final result = show(const LiquidMenu(children: []));
      await t.pump();
      platform.emit(const LiquidMenuDismissed(menuId: 'lm_stale-0000'));
      var completed = false;
      unawaited(result.then((_) => completed = true));
      await t.pump();
      expect(completed, isFalse);
      platform.emit(LiquidMenuDismissed(menuId: platform.shows.single.menuId));
      expect(await result, isNull);
    });

    testWidgets('a second show supersedes the first session', (t) async {
      await mount(t);
      final first = show(const LiquidMenu(children: []));
      await t.pump();
      final second = show(const LiquidMenu(children: []));
      await t.pump();
      expect(await first, isNull);
      platform.emit(LiquidMenuDismissed(menuId: platform.shows.last.menuId));
      expect(await second, isNull);
      expect(platform.shows, hasLength(2));
    });

    testWidgets('keepsMenuPresented actions fire onSelected repeatedly', (
      t,
    ) async {
      await mount(t);
      var taps = 0;
      final menu = LiquidMenu(
        children: [
          LiquidMenuAction(
            title: 'Pin',
            keepsMenuPresented: true,
            onSelected: () => taps++,
          ),
        ],
      );
      final result = show(menu);
      await t.pump();
      final menuId = platform.shows.single.menuId;
      final actionId =
          ((platform.shows.single.menu['items'] as List).single as Map)['id']
              as String;
      platform.emit(LiquidMenuActionEvent(menuId: menuId, actionId: actionId));
      platform.emit(LiquidMenuActionEvent(menuId: menuId, actionId: actionId));
      await t.pump();
      expect(taps, 2);
      platform.emit(LiquidMenuDismissed(menuId: menuId));
      expect(await result, isNull);
    });

    testWidgets('rejected show falls through to the Flutter fallback', (
      t,
    ) async {
      await mount(t);
      platform.acceptShow = false;
      final result = show(const LiquidMenu(children: []));
      await t.pumpAndSettle();
      // The fallback opened a showMenu route — dismiss it by tapping the barrier.
      await t.tapAt(const Offset(10, 10));
      await t.pumpAndSettle();
      expect(await result, isNull);
    });
  });
}
