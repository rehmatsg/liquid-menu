import 'menu_elements.dart';
import 'menu_icon.dart';

/// A native popup menu (`UIMenu`). The same shape serves the root menu and —
/// through [LiquidSubmenu]/[LiquidMenuSection] — nested content.
final class LiquidMenu {
  const LiquidMenu({
    this.title = '',
    this.image,
    this.identifier,
    this.children = const [],
    this.preferredElementSize = .automatic,
  });

  /// Shown as the menu's header title when non-empty.
  final String title;
  final LiquidMenuIcon? image;

  /// `UIMenu.Identifier` — mainly useful for debugging.
  final String? identifier;

  final List<LiquidMenuElement> children;
  final MenuElementSize preferredElementSize;

  Map<String, Object?> toMap(
    Map<String, Object?> Function(LiquidMenuElement) serializeChild,
  ) => {
    'title': title,
    if (image != null) 'image': image!.toMap(),
    if (identifier != null) 'identifier': identifier,
    'elementSize': preferredElementSize.name,
    'options': const <String, Object?>{},
    'items': [for (final e in children) serializeChild(e)],
  };
}
