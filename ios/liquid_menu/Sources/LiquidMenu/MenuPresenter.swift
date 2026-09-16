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

    let control = MenuAnchorControl(frame: anchor.frame)
    control.attachmentPoint = anchor.attachmentPoint
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
  /// The attachment point inside the anchor view's bounds. A point anchor
  /// attaches at its own center (the point); a rect anchor defers to the
  /// system's edge choice.
  var attachmentPoint: CGPoint? {
    switch self {
    case .point: return CGPoint(x: 0.5, y: 0.5)
    case .rect: return nil
    }
  }
}
