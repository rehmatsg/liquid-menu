// Log markers are the recorder's start/stop contract.
// ignore_for_file: avoid_print

import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:flutter/services.dart';
import 'package:liquid_menu/liquid_menu.dart';

/// A single named preview in a demo reel: presents a menu and awaits however
/// long it should stay on screen. Dismissal between previews is handled by
/// the reel runner.
typedef DemoPreview = Future<void> Function(BuildContext context);

/// Boots a full-screen reel used to record demo videos. Writing a new demo is
/// just a map of name → preview.
///
/// Around the reel it prints the log markers the recorder keys off:
///
///   `<prefix>:<name>:START`   `<prefix>:<name>:END`   …   `<prefix>:DONE`
///
/// The recorder waits for the first `<prefix>:DONE` (build good, screen
/// clean), starts recording, hot-restarts to replay, stops at the second.
void runMenuDemoReel({
  required String prefix,
  required Map<String, DemoPreview> previews,
  Duration settle = const Duration(seconds: 2),
  Duration gap = const Duration(milliseconds: 1800),
}) {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
  runApp(_ReelApp(prefix: prefix, previews: previews, settle: settle, gap: gap));
}

class _ReelApp extends StatelessWidget {
  const _ReelApp({
    required this.prefix,
    required this.previews,
    required this.settle,
    required this.gap,
  });

  final String prefix;
  final Map<String, DemoPreview> previews;
  final Duration settle;
  final Duration gap;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: .ltr,
      child: _ReelStage(prefix: prefix, previews: previews, settle: settle, gap: gap),
    );
  }
}

class _ReelStage extends StatefulWidget {
  const _ReelStage({
    required this.prefix,
    required this.previews,
    required this.settle,
    required this.gap,
  });

  final String prefix;
  final Map<String, DemoPreview> previews;
  final Duration settle;
  final Duration gap;

  @override
  State<_ReelStage> createState() => _ReelStageState();
}

class _ReelStageState extends State<_ReelStage> {
  String? _active;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_run()));
  }

  Future<void> _run() async {
    await Future<void>.delayed(widget.settle);
    for (final entry in widget.previews.entries) {
      if (!mounted) return;
      setState(() => _active = entry.key);
      print('${widget.prefix}:${entry.key}:START');
      try {
        await entry.value(context);
      } finally {
        await liquidMenus.dismiss();
      }
      print('${widget.prefix}:${entry.key}:END');
      if (!mounted) return;
      setState(() => _active = null);
      await Future<void>.delayed(widget.gap);
    }
    print('${widget.prefix}:DONE');
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF0F172A),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: .topLeft,
            end: .bottomRight,
            colors: [Color(0xFF1E293B), Color(0xFF0F172A), Color(0xFF1E1B4B)],
          ),
        ),
        child: Center(
          child: switch (_active) {
            'hero' => const _TriggerCard(title: 'Feed', subtitle: 'tap position menu'),
            'compact' => const _TriggerCard(title: 'Row', subtitle: 'compact menu'),
            'deferred' => const _TriggerCard(title: 'Jobs', subtitle: 'deferred items'),
            'pulldown' => const _TriggerCard(title: 'Mode', subtitle: 'pulldown menu'),
            _ => const SizedBox.shrink(),
          },
        ),
      ),
    );
  }
}

class _TriggerCard extends StatelessWidget {
  const _TriggerCard({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: .circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Column(
        mainAxisSize: .min,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: .w600,
              decoration: .none,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.55),
              fontSize: 13,
              decoration: .none,
            ),
          ),
        ],
      ),
    );
  }
}
