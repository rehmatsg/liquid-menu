import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_menu/liquid_menu.dart';
import 'package:liquid_menu/liquid_menu_platform_interface.dart';
import 'package:liquid_menu/src/menu_engine.dart';

import 'fake_platform.dart';

/// Exercises the Flutter `showMenu` fallback path (non-iOS or rejected native).
void main() {
  late FakeLiquidMenuPlatform platform;

  setUp(() {
    platform = FakeLiquidMenuPlatform()..nativeMenu = false;
    LiquidMenuPlatform.instance = platform;
    LiquidMenuEngine.instance.resetForTests();
    LiquidMenuEngine.debugTargetPlatformOverride = .android;
  });

  tearDown(() {
    LiquidMenuEngine.debugTargetPlatformOverride = null;
  });

  Widget app(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('fallback renders actions; tapping returns the value', (t) async {
    Object? selected;
    Object? callbackValue;
    await t.pumpWidget(
      app(
        Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              selected = await liquidMenus.show<Object?>(
                context: context,
                menu: LiquidMenu(
                  children: [
                    LiquidMenuAction(
                      title: 'First',
                      value: 'first',
                      onSelected: () => callbackValue = 'cb',
                    ),
                    const LiquidMenuDivider(),
                    LiquidMenuAction(
                      title: 'Gone',
                      destructive: true,
                      enabled: false,
                    ),
                  ],
                ),
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    );

    await t.tap(find.text('open'));
    await t.pumpAndSettle();
    expect(find.text('First'), findsOneWidget);
    expect(find.text('Gone'), findsOneWidget);

    await t.tap(find.text('First'));
    await t.pumpAndSettle();
    expect(selected, 'first');
    expect(callbackValue, 'cb');
  });

  testWidgets('fallback renders sections with headers and a divider', (
    t,
  ) async {
    await t.pumpWidget(
      app(
        Builder(
          builder: (context) => TextButton(
            onPressed: () => liquidMenus.show(
              context: context,
              menu: LiquidMenu(
                children: [
                  LiquidMenuAction(title: 'Top'),
                  LiquidMenuSection(
                    title: 'Section Title',
                    children: [LiquidMenuAction(title: 'Inside', state: .on)],
                  ),
                ],
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );

    await t.tap(find.text('open'));
    await t.pumpAndSettle();
    expect(find.text('Section Title'), findsOneWidget);
    expect(find.text('Inside'), findsOneWidget);
    expect(find.byType(PopupMenuDivider), findsWidgets);
    // checkmark rendered for the .on row
    expect(find.byIcon(Icons.check), findsOneWidget);
  });

  testWidgets('fallback submenu opens a second popup', (t) async {
    Object? selected;
    await t.pumpWidget(
      app(
        Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              selected = await liquidMenus.show(
                context: context,
                menu: LiquidMenu(
                  children: [
                    LiquidSubmenu(
                      title: 'More',
                      children: [
                        LiquidMenuAction(title: 'Deep', value: 'deep'),
                      ],
                    ),
                  ],
                ),
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    );

    await t.tap(find.text('open'));
    await t.pumpAndSettle();
    expect(find.text('More'), findsOneWidget);

    await t.tap(find.text('More'));
    await t.pumpAndSettle();
    expect(find.text('Deep'), findsOneWidget);

    await t.tap(find.text('Deep'));
    await t.pumpAndSettle();
    expect(selected, 'deep');
  });

  testWidgets('fallback resolves deferred elements eagerly', (t) async {
    await t.pumpWidget(
      app(
        Builder(
          builder: (context) => TextButton(
            onPressed: () => liquidMenus.show(
              context: context,
              menu: LiquidMenu(
                children: [
                  LiquidMenuDeferred(
                    loader: () async => [LiquidMenuAction(title: 'Loaded')],
                  ),
                ],
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );

    await t.tap(find.text('open'));
    await t.pumpAndSettle();
    expect(find.text('Loaded'), findsOneWidget);
  });

  testWidgets('barrier tap dismisses with null', (t) async {
    Object? selected = 'unset';
    await t.pumpWidget(
      app(
        Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              selected = await liquidMenus.show(
                context: context,
                menu: LiquidMenu(children: [LiquidMenuAction(title: 'A')]),
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    );

    await t.tap(find.text('open'));
    await t.pumpAndSettle();
    await t.tapAt(const Offset(5, 5));
    await t.pumpAndSettle();
    expect(selected, isNull);
  });
}
