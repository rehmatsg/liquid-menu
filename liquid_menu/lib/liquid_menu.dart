/// Native iOS popup menus for Flutter: a real `UIMenu` presented at a tap
/// point or a widget's bounds, bridged through an invisible overlay control.
/// On non-iOS (or iOS < 17.4) the same model renders as a Flutter `showMenu`.
///
/// ```dart
/// // Imperative — anchored to the calling widget's rect:
/// final picked = await liquidMenus.show(context: context, menu: menu);
///
/// // At the exact tap position (e.g. from VanceInkWell.onTapDown):
/// final picked = await liquidMenus.showAt(details.globalPosition, context: context, menu: menu);
///
/// // Declarative — a region that owns the trigger:
/// LiquidMenuRegion(menu: menu, child: MyTriggerVisual())
/// ```
library;

export 'src/menu.dart';
export 'src/menu_anchor.dart';
export 'src/menu_elements.dart';
export 'src/menu_event.dart';
export 'src/menu_icon.dart';
export 'src/menu_region.dart';
export 'src/menus.dart' show LiquidMenus, liquidMenus;
