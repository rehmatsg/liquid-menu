import 'dart:typed_data';

import 'package:flutter/painting.dart' show Color;

/// A row's leading image (`UIAction.image` / `UIMenu.image`).
sealed class LiquidMenuIcon {
  const LiquidMenuIcon();

  Map<String, Object?> toMap();
}

/// An SF Symbol by name, with optional weight, scale, rendering mode and
/// palette colors — the native `UIImage.SymbolConfiguration` surface.
final class LiquidMenuSfSymbol extends LiquidMenuIcon {
  const LiquidMenuSfSymbol(
    this.name, {
    this.weight,
    this.scale,
    this.renderingMode = .automatic,
    this.palette = const [],
  });

  final String name;
  final SymbolWeight? weight;
  final SymbolScale? scale;
  final SymbolRenderingMode renderingMode;

  /// Palette colors for `.palette` mode; the first is also the base color for
  /// `.hierarchical`.
  final List<Color> palette;

  @override
  Map<String, Object?> toMap() => {
    'kind': 'sfSymbol',
    'name': name,
    if (weight != null) 'weight': weight!.name,
    if (scale != null) 'scale': scale!.name,
    if (renderingMode != .automatic) 'renderingMode': renderingMode.name,
    if (palette.isNotEmpty) 'palette': [for (final c in palette) c.toARGB32()],
  };
}

/// A bitmap supplied as encoded image bytes (PNG/etc.). `templated` makes
/// single-color artwork pick up the menu's own tint.
final class LiquidMenuImage extends LiquidMenuIcon {
  const LiquidMenuImage(this.bytes, {this.templated = false});

  final Uint8List bytes;
  final bool templated;

  @override
  Map<String, Object?> toMap() => {
    'kind': 'image',
    'bytes': bytes,
    'templated': templated,
  };
}

/// `UIImage.SymbolWeight` as a wire-friendly enum.
enum SymbolWeight {
  ultraLight,
  thin,
  light,
  regular,
  medium,
  semibold,
  bold,
  heavy,
  black,
}

/// `UIImage.SymbolScale` as a wire-friendly enum.
enum SymbolScale { small, medium, large }

/// `UIImage.SymbolRenderingMode` as a wire-friendly enum.
enum SymbolRenderingMode {
  automatic,
  monochrome,
  hierarchical,
  palette,
  multicolor,
}
