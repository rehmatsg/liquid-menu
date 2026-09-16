import 'package:flutter/cupertino.dart';
import 'package:liquid_menu/liquid_menu.dart';

void main() => runApp(const _DemoApp());

class _DemoApp extends StatelessWidget {
  const _DemoApp();

  @override
  Widget build(BuildContext context) => const CupertinoApp(
        theme: CupertinoThemeData(brightness: .light),
        home: _DemoScreen(),
      );
}

class _DemoScreen extends StatefulWidget {
  const _DemoScreen();

  @override
  State<_DemoScreen> createState() => _DemoScreenState();
}

/// The demo menu, shared with the integration test.
LiquidMenu buildDemoMenu() => LiquidMenu(children: [
      LiquidMenuAction(
        id: 'for_you',
        title: 'For You',
        value: 'for_you',
        icon: const LiquidMenuSfSymbol('sparkles'),
        state: .on,
      ),
      LiquidMenuAction(
        title: 'New Jobs',
        value: 'new_jobs',
        icon: const LiquidMenuSfSymbol('bolt.fill'),
      ),
      const LiquidMenuDivider(),
      LiquidMenuSection(title: 'More', children: [
        LiquidMenuAction(title: 'Saved', icon: const LiquidMenuSfSymbol('bookmark')),
        LiquidSubmenu(
          title: 'Filters',
          icon: const LiquidMenuSfSymbol('line.3.horizontal.decrease.circle'),
          children: [
            LiquidMenuAction(title: 'Remote only', state: .on),
            LiquidMenuAction(title: 'Full-time', state: .off),
          ],
        ),
      ]),
      const LiquidMenuDivider(),
      LiquidMenuAction(
        title: 'Reset feed',
        destructive: true,
        icon: const LiquidMenuSfSymbol('arrow.counterclockwise'),
      ),
      LiquidMenuAction(title: 'Hidden item', hidden: true),
      LiquidMenuAction(title: 'Disabled item', enabled: false),
    ]);

class _DemoScreenState extends State<_DemoScreen> {
  String _last = 'nothing yet';
  bool? _native;

  static const _autoPresent = bool.fromEnvironment('AUTOPRESENT');

  @override
  void initState() {
    super.initState();
    liquidMenus.supportsNativeMenu.then((v) => setState(() => _native = v));
    if (_autoPresent) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 800));
        if (!mounted) return;
        final size = MediaQuery.sizeOf(context);
        final picked = await liquidMenus.showAt<String>(
          Offset(size.width / 2, size.height * 0.45),
          context: context,
          menu: _menu,
        );
        _report(picked);
      });
    }
    liquidMenus.events.listen((e) {
      if (e is LiquidMenuActionEvent) setState(() => _last = 'action ${e.actionId}');
    });
  }

  LiquidMenu get _menu => buildDemoMenu();

  void _report(Object? value) {
    setState(() => _last = 'selected: ${value ?? '(dismissed)'}');
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text('liquid_menu')),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text('native UIMenu: ${_native ?? 'checking…'}'),
            const SizedBox(height: 4),
            Text('last: $_last'),
            const SizedBox(height: 24),

            // 1. Tap-to-point region: the menu attaches at the tap.
            LiquidMenuRegion(
              menu: _menu,
              onSelected: _report,
              child: Container(
                height: 120,
                alignment: .center,
                decoration: BoxDecoration(
                  color: const Color(0xFFEDE9FE),
                  borderRadius: .circular(16),
                ),
                child: const Text('tap anywhere here\n(menu opens at the tap)'),
              ),
            ),
            const SizedBox(height: 16),

            // 2. Button-rect anchor — pulldown off the trigger's bounds.
            LiquidMenuRegion(
              menu: _menu,
              anchor: .triggerRect,
              onSelected: _report,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                alignment: .center,
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: .circular(12),
                ),
                child: const Text('pulldown (rect anchor)'),
              ),
            ),
            const SizedBox(height: 16),

            // 3. Manual trigger via builder — the child owns its gesture.
            LiquidMenuRegion.builder(
              menu: _menu,
              anchor: .triggerRect,
              builder: (context, show) => CupertinoButton.filled(
                onPressed: show,
                child: const Text('builder / manual show'),
              ),
            ),
            const SizedBox(height: 16),

            // 4. Imperative at a point.
            Builder(
              builder: (context) => CupertinoButton(
                onPressed: () async {
                  final size = MediaQuery.sizeOf(context);
                  final picked = await liquidMenus.showAt<String>(
                    Offset(size.width / 2, size.height * 0.4),
                    context: context,
                    menu: _menu,
                  );
                  _report(picked);
                },
                child: const Text('showLiquidMenuAt (center-top)'),
              ),
            ),
            const SizedBox(height: 16),

            // 5. Imperative anchored to the button itself.
            Builder(
              builder: (context) => CupertinoButton(
                onPressed: () async {
                  final picked = await liquidMenus.show<String>(
                    context: context,
                    menu: _menu,
                  );
                  _report(picked);
                },
                child: const Text('showLiquidMenu (rect)'),
              ),
            ),
            const SizedBox(height: 16),

            // 6. Deferred content.
            CupertinoButton(
              onPressed: () => liquidMenus.show(
                context: context,
                menu: LiquidMenu(children: [
                  LiquidMenuAction(title: 'Static'),
                  LiquidMenuDeferred(loader: () async {
                    await Future<void>.delayed(const Duration(milliseconds: 400));
                    return [LiquidMenuAction(title: 'Loaded late')];
                  }),
                ]),
              ),
              child: const Text('deferred items'),
            ),
          ],
        ),
      ),
    );
  }
}
