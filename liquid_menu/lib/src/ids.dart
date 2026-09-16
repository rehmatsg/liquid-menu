import 'dart:math';

final Random _rng = Random.secure();

/// Wire-id minting: `lm_<sessionPrefix>_<counter>`. The session prefix is
/// random per isolate and sent in `handshake` — native flushes on every
/// handshake, which clears stale state after a hot restart.
final class MenuIds {
  MenuIds._();

  static final String session = List.generate(
    6,
    (_) => _rng.nextInt(36).toRadixString(36),
  ).join();
  static int _counter = 0;

  static String mint() =>
      'lm_$session-${(_counter++).toString().padLeft(4, '0')}';
}
