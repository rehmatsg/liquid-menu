import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:liquid_menu/liquid_menu.dart';

import 'demo_harness.dart';

/// The showcase reel for liquid-menu. Run via tool/record_demo.sh — the
/// markers it prints drive the recorder's start/stop.
void main() => runMenuDemoReel(prefix: 'MENU', previews: {
      // The range shot: symbols, checkmark state, a titled section, a nested
      // submenu with its own states + divider, destructive and disabled rows.
      'hero': (context) async {
        final size = MediaQuery.sizeOf(context);
        unawaited(liquidMenus.showAt<String>(
          Offset(size.width * 0.5, size.height * 0.42),
          context: context,
          menu: LiquidMenu(children: [
            LiquidMenuAction(
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
            LiquidMenuSection(title: 'Feed tools', children: [
              LiquidMenuAction(
                title: 'Saved',
                icon: const LiquidMenuSfSymbol('bookmark'),
              ),
              LiquidSubmenu(
                title: 'Filters',
                icon: const LiquidMenuSfSymbol(
                  'line.3.horizontal.decrease.circle',
                ),
                children: [
                  LiquidMenuAction(title: 'Remote only', state: .on),
                  LiquidMenuAction(title: 'Full-time', state: .off),
                  LiquidMenuAction(title: 'Internship', state: .off),
                  const LiquidMenuDivider(),
                  LiquidMenuAction(
                    title: 'Clear filters',
                    destructive: true,
                    icon: const LiquidMenuSfSymbol('xmark.circle'),
                  ),
                ],
              ),
            ]),
            const LiquidMenuDivider(),
            LiquidMenuAction(
              title: 'Reset feed',
              destructive: true,
              icon: const LiquidMenuSfSymbol('arrow.counterclockwise'),
            ),
            LiquidMenuAction(
              title: 'Coming soon',
              enabled: false,
              icon: const LiquidMenuSfSymbol('wand.and.stars'),
            ),
          ]),
        ));
        await Future<void>.delayed(const Duration(milliseconds: 3200));
      },

      // Compact element sizing — the dense variant iOS offers.
      'compact': (context) async {
        final size = MediaQuery.sizeOf(context);
        unawaited(liquidMenus.showAt<String>(
          Offset(size.width * 0.32, size.height * 0.5),
          context: context,
          menu: LiquidMenu(
            preferredElementSize: .small,
            children: [
              LiquidMenuAction(
                title: 'Refresh',
                icon: const LiquidMenuSfSymbol('arrow.clockwise'),
              ),
              LiquidMenuAction(
                title: 'Copy link',
                icon: const LiquidMenuSfSymbol('link'),
              ),
              LiquidMenuAction(
                title: 'Share…',
                icon: const LiquidMenuSfSymbol('square.and.arrow.up'),
              ),
            ],
          ),
        ));
        await Future<void>.delayed(const Duration(milliseconds: 2600));
      },

      // Deferred items resolve while the menu is open.
      'deferred': (context) async {
        final size = MediaQuery.sizeOf(context);
        unawaited(liquidMenus.showAt<String>(
          Offset(size.width * 0.68, size.height * 0.45),
          context: context,
          menu: LiquidMenu(children: [
            LiquidMenuAction(
              title: 'Applied',
              icon: const LiquidMenuSfSymbol('checkmark.circle'),
            ),
            LiquidMenuDeferred(loader: () async {
              await Future<void>.delayed(const Duration(milliseconds: 700));
              return [
                LiquidMenuAction(
                  title: 'Saved searches',
                  icon: const LiquidMenuSfSymbol('magnifyingglass'),
                ),
                LiquidMenuAction(
                  title: 'Alerts',
                  icon: const LiquidMenuSfSymbol('bell.badge'),
                ),
              ];
            }),
          ]),
        ));
        await Future<void>.delayed(const Duration(milliseconds: 3000));
      },

      // Rect anchor — the pulldown variant attached to the trigger's bounds.
      'pulldown': (context) async {
        final size = MediaQuery.sizeOf(context);
        unawaited(liquidMenus.show<String>(
          context: context,
          anchor: LiquidMenuAnchor.rect(
            Rect.fromCenter(
              center: Offset(size.width * 0.5, size.height * 0.46),
              width: 180,
              height: 60,
            ),
          ),
          menu: LiquidMenu(children: [
            LiquidMenuAction(title: 'For You', value: 'for_you', state: .on),
            LiquidMenuAction(title: 'New Jobs', value: 'new_jobs'),
            LiquidMenuAction(title: 'Remote', value: 'remote'),
          ]),
        ));
        await Future<void>.delayed(const Duration(milliseconds: 2800));
      },
    });
