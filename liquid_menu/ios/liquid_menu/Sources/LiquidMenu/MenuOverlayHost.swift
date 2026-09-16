import UIKit

/// Installs and owns the overlay the menus anchor into. Lives for the app's
/// lifetime as a singleton so presentation state survives individual menus
/// (and a hot restart is handled explicitly via the plugin's handshake flush).
///
/// The overlay is a transparent, non-interactive view added above the app's
/// own content **in the same window**, so the anchor control lives in a real
/// view hierarchy for the context-menu interaction to attach to.
@MainActor
public final class MenuOverlayHost {
  public static let shared = MenuOverlayHost()

  /// The container menus anchor into. Non-nil once [ensureInstalled] ran while
  /// a window existed.
  public private(set) var hostView: UIView?

  private var observersAdded = false

  private init() {}

  /// Ensures the overlay is attached to the active window. Idempotent, and
  /// safe to call before a window exists — it retries on the next runloop and
  /// on scene activation.
  @discardableResult
  public func ensureInstalled() -> Bool {
    addObserversIfNeeded()
    guard hostView == nil else { return true }
    guard let window = Self.activeWindow(), let root = window.rootViewController else {
      DispatchQueue.main.async { [weak self] in
        guard let self, self.hostView == nil else { return }
        if Self.activeWindow()?.rootViewController != nil { self.ensureInstalled() }
      }
      return false
    }
    install(in: root)
    return true
  }

  private func install(in root: UIViewController) {
    let host = UIView()
    host.isUserInteractionEnabled = false
    host.backgroundColor = .clear
    host.translatesAutoresizingMaskIntoConstraints = false
    root.view.addSubview(host)

    NSLayoutConstraint.activate([
      host.topAnchor.constraint(equalTo: root.view.topAnchor),
      host.bottomAnchor.constraint(equalTo: root.view.bottomAnchor),
      host.leadingAnchor.constraint(equalTo: root.view.leadingAnchor),
      host.trailingAnchor.constraint(equalTo: root.view.trailingAnchor),
    ])

    hostView = host
  }

  /// Keeps the overlay frontmost if the app later adds sibling views.
  func bringToFront() {
    guard let host = hostView, let superview = host.superview else { return }
    superview.bringSubviewToFront(host)
  }

  /// The window the overlay installs into: the foreground-active scene's key
  /// window, with progressively looser fallbacks.
  public static func activeWindow() -> UIWindow? {
    let windowScenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
    let scene = windowScenes.first { $0.activationState == .foregroundActive }
      ?? windowScenes.first { $0.activationState == .foregroundInactive }
      ?? windowScenes.first
    guard let scene else { return nil }
    return scene.windows.first { $0.isKeyWindow } ?? scene.windows.first
  }

  private func addObserversIfNeeded() {
    guard !observersAdded else { return }
    observersAdded = true
    NotificationCenter.default.addObserver(
      forName: UIScene.didActivateNotification,
      object: nil,
      queue: .main
    ) { [weak self] _ in
      MainActor.assumeIsolated {
        guard let self else { return }
        if self.hostView == nil { self.ensureInstalled() } else { self.bringToFront() }
      }
    }
  }
}
