import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:liquid_menu/liquid_menu.dart';
import 'package:liquid_menu_example/main.dart' as app;

/// The spike: present a real native UIMenu, tap a row, and verify the whole
/// event round-trip through the method/event channels.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('native UIMenu presents, routes action, dismisses', (tester) async {
    app.main();
    await tester.pumpAndSettle();

    // Subscribe BEFORE presenting — the broadcast stream drops events with no
    // listener attached.
    final presentedFuture = liquidMenus.events
        .where((e) => e is LiquidMenuPresented)
        .cast<LiquidMenuPresented>()
        .first
        .timeout(const Duration(seconds: 5));
    final actionFuture = liquidMenus.events
        .where((e) => e is LiquidMenuActionEvent)
        .cast<LiquidMenuActionEvent>()
        .first
        .timeout(const Duration(seconds: 5));
    final dismissedFuture = liquidMenus.events
        .where((e) => e is LiquidMenuDismissed)
        .cast<LiquidMenuDismissed>()
        .first
        .timeout(const Duration(seconds: 5));

    // Present at the point verified visually (menu renders centered-ish on
    // it); the context is only used by the Flutter fallback path.
    final context = tester.element(find.text('tap anywhere here\n(menu opens at the tap)'));
    final resultFuture = liquidMenus.showAt<String>(
      const Offset(200, 390),
      context: context,
      menu: app.buildDemoMenu(),
    );

    final presented = await presentedFuture;
    expect(presented.menuId, startsWith('lm_'));
    expect(liquidMenus.isPresented, isTrue);
    await tester.pump(const Duration(milliseconds: 600));

    // Synthesized touches can't reach the context-menu window — drive the
    // selection through the plugin's testing hook, which runs the same
    // handler a real row tap invokes.
    await liquidMenus.debugSelect('for_you');

    final action = await actionFuture;
    expect(action.menuId, presented.menuId);
    expect(action.actionId, isNotEmpty);

    final dismissed = await dismissedFuture;
    expect(dismissed.menuId, presented.menuId);
    await tester.pumpAndSettle();
    expect(liquidMenus.isPresented, isFalse);

    // The row's value resolves the show future.
    expect(await resultFuture, 'for_you');
  });
}
