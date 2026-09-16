import UIKit

/// Lifecycle events of one presented menu.
public enum MenuLifecycleEvent: Equatable, Sendable {
  /// The system began presenting the menu.
  case presented
  /// The menu finished dismissing (selection or cancellation alike).
  case dismissed
}

/// Presents `UIMenu`s through invisible anchor controls in an overlay host.
///
/// One menu at a time: presenting while presented dismisses the live menu
/// first (the system serializes the transition).
@MainActor
public final class MenuPresenter {
  public init() {}

  /// Whether a menu is currently presented (or mid-presentation).
  public private(set) var isPresented = false

  /// Whether programmatic presentation is supported on this OS.
  /// `UIControl.performPrimaryAction` is iOS 17.4+.
  public static var isSupported: Bool {
    if #available(iOS 17.4, *) { return true }
    return false
  }

  private weak var control: MenuAnchorControl?
  /// The live presentation's action router — lets `debugSelect` drive the
  /// same path a real row tap does (used by integration tests; synthesized
  /// touches can't reach the context-menu window).
  private var actionHandler: (@MainActor (String) -> Void)?
  /// Supersedes callbacks from a replaced control: only the latest
  /// presentation's events reach listeners.
  private var generation = 0

  /// Per-presentation flags shared by the control's lifecycle closures and the
  /// watchdog — guards against double `dismissed` emissions.
  private final class _Presentation {
    var presented = false
    var dismissed = false
  }

  /// Presents `spec`'s menu at `anchor` inside `host`.
  ///
  /// - `onAction`: fired per action tap (may fire repeatedly for
  ///   `keepsMenuPresented` rows).
  /// - `onLifecycle`: `.presented` then exactly one `.dismissed`.
  ///
  /// Returns `false` when programmatic presentation is unavailable
  /// (iOS < 17.4) — the caller should fall back.
  @discardableResult
  public func present(
    _ spec: MenuSpec,
    at anchor: MenuAnchor,
    in host: UIView,
    onAction: @escaping @MainActor (String) -> Void,
    onLifecycle: @escaping @MainActor (MenuLifecycleEvent) -> Void
  ) -> Bool {
    guard #available(iOS 17.4, *) else { return false }

    generation += 1
    let gen = generation
    control?.contextMenuInteraction?.dismissMenu()
    control?.removeFromSuperview()

    let (controlFrame, attachment) = anchor.resolvedControl(in: host.bounds)
    let control = MenuAnchorControl(frame: controlFrame)
    control.attachmentUnitPoint = attachment
    actionHandler = onAction
    control.presentedMenu = MenuBuilder.menu(from: spec, onAction: onAction)
    let state = _Presentation()
    control.onWillPresent = { [weak self] in
      guard let self, self.generation == gen, !state.dismissed else { return }
      state.presented = true
      self.isPresented = true
      onLifecycle(.presented)
    }
    control.onWillDismiss = { [weak self, weak control] in
      guard let self, self.generation == gen, !state.dismissed else { return }
      state.dismissed = true
      self.isPresented = false
      onLifecycle(.dismissed)
      control?.removeFromSuperview()
    }

    host.addSubview(control)
    host.layoutIfNeeded()
    self.control = control

    // The context-menu interaction installs on window insertion — give it a
    // runloop turn before asking the button to perform its primary action.
    DispatchQueue.main.async { [weak control] in
      control?.performPrimaryAction()
    }

    // If the system never began presenting, `willDisplayMenuFor` won't fire
    // and the caller would hang — tear down and report dismissal instead.
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self, weak control] in
      guard let self, self.generation == gen, !state.presented, !state.dismissed else { return }
      state.dismissed = true
      control?.removeFromSuperview()
      if self.control === control { self.control = nil }
      onLifecycle(.dismissed)
    }
    return true
  }

  /// Dismisses the presented menu, if any. No-op when nothing is up.
  /// The anchor removes itself when the dismissal finishes.
  public func dismiss() {
    control?.contextMenuInteraction?.dismissMenu()
  }

  /// Testing hook: routes `actionId` through the live menu's action handler
  /// and dismisses — what a real row tap does end-to-end. Integration tests
  /// need this because synthesized touches never reach the menu's window.
  public func debugSelect(_ actionId: String) {
    actionHandler?(actionId)
    dismiss()
  }
}

extension MenuAnchor {
  /// Gap between the trigger's edge and the menu's near edge.
  private static let rectGap: CGFloat = 6

  /// The invisible anchor control's frame plus the menu's attachment point
  /// inside it (unit coordinates).
  ///
  /// A `.point` anchor is a 1×1 at the touch — the menu's top edge lands on
  /// the tap. A `.rect` anchor is a 1pt strip offset `rectGap` **below** the
  /// rect when it sits in the container's upper half, else offset **above**
  /// it — so the menu hangs off the trigger rather than covering it. The
  /// attachment point's unit-y picks which side of the strip the menu lands
  /// on: near the strip's bottom → menu below; near the top → above. (UIKit
  /// still clamps or scrolls a menu too tall for either side.)
  func resolvedControl(in container: CGRect) -> (frame: CGRect, attachment: CGPoint) {
    switch self {
    case .point(let point):
      return (
        CGRect(x: point.x - 0.5, y: point.y - 0.5, width: 1, height: 1),
        CGPoint(x: 0.5, y: 0.5)
      )
    case .rect(let rect):
      let below = rect.midY <= container.midY
      let strip = below
        ? CGRect(x: rect.minX, y: rect.maxY + Self.rectGap, width: rect.width, height: 1)
        : CGRect(x: rect.minX, y: rect.minY - Self.rectGap - 1, width: rect.width, height: 1)
      return (strip, CGPoint(x: 0.5, y: below ? 1 : 0))
    }
  }
}
