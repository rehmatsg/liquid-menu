import UIKit

/// The native facade — mirror of the Dart `LiquidMenus` API for native apps.
///
/// ```swift
/// LiquidMenu.present(
///   MenuSpec(children: [.action(MenuAction(id: "save", title: "Save"))]),
///   at: .point(tapLocation)
/// ) { id in
///   print("selected", id)
/// }
/// ```
@MainActor
public enum LiquidMenu {

  /// Whether programmatic native menus are supported (iOS 17.4+).
  public static var isSupported: Bool { MenuPresenter.isSupported }

  /// Whether a menu is currently up.
  public static var isPresented: Bool { presenter.isPresented }

  /// Presents `spec` anchored in the app's key window. Returns `false` when
  /// unsupported or no window is available yet.
  @discardableResult
  public static func present(
    _ spec: MenuSpec,
    at anchor: MenuAnchor,
    onAction: @escaping @MainActor (String) -> Void = { _ in },
    onLifecycle: @escaping @MainActor (MenuLifecycleEvent) -> Void = { _ in }
  ) -> Bool {
    guard Self.isSupported, MenuOverlayHost.shared.ensureInstalled(),
          let host = MenuOverlayHost.shared.hostView else {
      return false
    }
    return presenter.present(
      spec,
      at: anchor,
      in: host,
      onAction: onAction,
      onLifecycle: onLifecycle
    )
  }

  /// Dismisses the presented menu, if any.
  public static func dismiss() {
    presenter.dismiss()
  }

  private static let presenter = MenuPresenter()
}
