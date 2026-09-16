import UIKit

/// Where a presented menu is anchored, in **window coordinates**.
public enum MenuAnchor: Equatable, Sendable {
  /// Anchor to a rectangle — typically the trigger control's global bounds.
  /// The menu hangs off the rect's bottom edge (pulldown style) when the
  /// rect is in the window's upper half, or off its top edge when lower.
  case rect(CGRect)

  /// Anchor at a point — typically the tap location. The attachment view is a
  /// minimal rect centered on the point so the menu tracks the touch itself.
  case point(CGPoint)

  /// The window-space frame the anchor view occupies — see
  /// `MenuPresenter` for how rect anchors become a thin strip offset from
  /// the trigger, which is what keeps the menu from covering it.
  public var frame: CGRect {
    switch self {
    case .rect(let rect):
      return rect
    case .point(let point):
      return CGRect(x: point.x - 0.5, y: point.y - 0.5, width: 1, height: 1)
    }
  }
}

/// One element in a menu's child list.
public enum MenuElement {
  /// A tappable row (`UIAction`).
  case action(MenuAction)

  /// A nested menu: renders as a row that navigates to a second page.
  case submenu(MenuSpec)

  /// An inline section: its children render as one separated group, with
  /// `spec.title` as the section header when non-empty.
  case section(MenuSpec)

  /// A separator between the surrounding rows — sugar for splitting the
  /// enclosing run into inline sections.
  case divider

  /// Rows resolved when the menu opens (`UIDeferredMenuElement`). The provider
  /// runs on display; keep it fast, the menu waits on it.
  case deferred(MenuDeferred)

  public static func == (lhs: MenuElement, rhs: MenuElement) -> Bool {
    switch (lhs, rhs) {
    case (.action(let a), .action(let b)): return a == b
    case (.submenu(let a), .submenu(let b)): return a == b
    case (.section(let a), .section(let b)): return a == b
    case (.divider, .divider): return true
    case (.deferred(let a), .deferred(let b)): return a.id == b.id
    default: return false
    }
  }
}

extension MenuElement: Equatable {}

/// A display-time content provider for a `.deferred` element.
public struct MenuDeferred {
  public var id: String
  public var provider: @MainActor () async throws -> [MenuElement]

  public init(id: String, provider: @escaping @MainActor () async throws -> [MenuElement]) {
    self.id = id
    self.provider = provider
  }
}

/// A tappable menu row (`UIAction`).
public struct MenuAction: Equatable {
  public var id: String
  public var title: String
  public var image: MenuIcon?
  public var state: MenuElementState
  public var isDestructive: Bool
  public var isDisabled: Bool
  public var isHidden: Bool
  public var keepsMenuPresented: Bool
  public var discoverabilityTitle: String?

  public init(
    id: String,
    title: String,
    image: MenuIcon? = nil,
    state: MenuElementState = .off,
    isDestructive: Bool = false,
    isDisabled: Bool = false,
    isHidden: Bool = false,
    keepsMenuPresented: Bool = false,
    discoverabilityTitle: String? = nil
  ) {
    self.id = id
    self.title = title
    self.image = image
    self.state = state
    self.isDestructive = isDestructive
    self.isDisabled = isDisabled
    self.isHidden = isHidden
    self.keepsMenuPresented = keepsMenuPresented
    self.discoverabilityTitle = discoverabilityTitle
  }
}

/// Checkmark state of a row (`UIMenuElement.State`).
public enum MenuElementState: String, Equatable, Sendable {
  case off
  case on
  case mixed
}

/// A menu or submenu (`UIMenu`). One spec serves the root menu, nested
/// submenus, and inline sections — the element wrapper decides the role.
public struct MenuSpec {
  public var title: String
  public var image: MenuIcon?
  public var identifier: String?
  public var options: MenuOptions
  public var preferredElementSize: MenuElementSize
  public var children: [MenuElement]

  public init(
    title: String = "",
    image: MenuIcon? = nil,
    identifier: String? = nil,
    options: MenuOptions = .init(),
    preferredElementSize: MenuElementSize = .automatic,
    children: [MenuElement] = []
  ) {
    self.title = title
    self.image = image
    self.identifier = identifier
    self.options = options
    self.preferredElementSize = preferredElementSize
    self.children = children
  }
}

extension MenuSpec: Equatable {
  public static func == (lhs: MenuSpec, rhs: MenuSpec) -> Bool {
    lhs.title == rhs.title
      && lhs.identifier == rhs.identifier
      && lhs.options == rhs.options
      && lhs.preferredElementSize == rhs.preferredElementSize
      && lhs.image == rhs.image
      && lhs.children == rhs.children
  }
}

/// `UIMenu.Options` as plain flags.
public struct MenuOptions: Equatable, Sendable {
  /// Renders the menu's row with a destructive appearance in its parent.
  public var isDestructive: Bool
  /// Only one child may be "on" at a time (radio semantics).
  public var singleSelection: Bool
  /// Renders as an icon palette (inline sections only).
  public var displayAsPalette: Bool

  public init(
    isDestructive: Bool = false,
    singleSelection: Bool = false,
    displayAsPalette: Bool = false
  ) {
    self.isDestructive = isDestructive
    self.singleSelection = singleSelection
    self.displayAsPalette = displayAsPalette
  }
}

/// `UIMenu.ElementSize` — the row density hint (iOS 16+).
public enum MenuElementSize: String, Equatable, Sendable {
  case automatic
  case small
  case medium
  case large
}

/// A row's leading image (`UIAction.image` / `UIMenu.image`).
public enum MenuIcon {
  /// An SF Symbol by name, with optional weight/scale/rendering/palette.
  case sfSymbol(SFSymbolIcon)

  /// A resolved bitmap (asset or byte-decoded on the caller side).
  case image(UIImage, templated: Bool)
}

extension MenuIcon: Equatable {
  public static func == (lhs: MenuIcon, rhs: MenuIcon) -> Bool {
    switch (lhs, rhs) {
    case (.sfSymbol(let a), .sfSymbol(let b)): return a == b
    case (.image(let a, let ta), .image(let b, let tb)): return a === b && ta == tb
    default: return false
    }
  }
}

/// An SF Symbol image and its `UIImage.SymbolConfiguration` parts.
public struct SFSymbolIcon: Equatable {
  public var name: String
  public var weight: SymbolWeight?
  public var scale: SymbolScale?
  public var renderingMode: SymbolRenderingMode
  public var palette: [UIColor]

  public init(
    name: String,
    weight: SymbolWeight? = nil,
    scale: SymbolScale? = nil,
    renderingMode: SymbolRenderingMode = .automatic,
    palette: [UIColor] = []
  ) {
    self.name = name
    self.weight = weight
    self.scale = scale
    self.renderingMode = renderingMode
    self.palette = palette
  }
}

/// `UIImage.SymbolWeight` as a wire-friendly enum.
public enum SymbolWeight: String, Equatable, Sendable {
  case ultraLight, thin, light, regular, medium, semibold, bold, heavy, black
}

/// `UIImage.SymbolScale` as a wire-friendly enum.
public enum SymbolScale: String, Equatable, Sendable {
  case small, medium, large
}

/// `UIImage.SymbolRenderingMode` as a wire-friendly enum.
public enum SymbolRenderingMode: String, Equatable, Sendable {
  case automatic, monochrome, hierarchical, palette, multicolor
}
