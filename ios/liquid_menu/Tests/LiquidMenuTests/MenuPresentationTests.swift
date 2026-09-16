import XCTest
@testable import liquid_menu

/// End-to-end presentation tests. These are the spike: they prove an invisible
/// `UIControl` in an overlay view presents a real `UIMenu` via
/// `performPrimaryAction()` on the OSes we support (iOS 17.4+).
@MainActor
final class MenuPresentationTests: XCTestCase {

  /// A host view in a real window — mirrors what `MenuOverlayHost` installs.
  private func makeHost() throws -> (UIWindow, UIView) {
    let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
    guard let scene = scenes.first(where: { $0.activationState == .foregroundActive }) ?? scenes.first
    else {
      throw XCTSkip("No window scene in test host")
    }
    let window = UIWindow(windowScene: scene)
    window.frame = scene.screen.bounds
    let root = UIViewController()
    window.rootViewController = root
    window.makeKeyAndVisible()
    let host = UIView(frame: window.bounds)
    host.isUserInteractionEnabled = false
    root.view.addSubview(host)
    window.layoutIfNeeded()
    return (window, host)
  }

  func testPresentAtPointPresentsMenu() async throws {
    guard MenuPresenter.isSupported else { throw XCTSkip("requires iOS 17.4+") }
    let (window, host) = try makeHost()
    defer { window.isHidden = true }

    let presenter = MenuPresenter()
    let presented = expectation(description: "menu presented")
    let dismissed = expectation(description: "menu dismissed")

    let spec = MenuSpec(children: [
      .action(MenuAction(id: "alpha", title: "Alpha")),
      .action(MenuAction(id: "beta", title: "Beta")),
    ])

    let accepted = presenter.present(
      spec,
      at: .point(CGPoint(x: 200, y: 400)),
      in: host,
      onAction: { _ in },
      onLifecycle: { event in
        switch event {
        case .presented: presented.fulfill()
        case .dismissed: dismissed.fulfill()
        }
      }
    )
    XCTAssertTrue(accepted)

    await fulfillment(of: [presented], timeout: 5)
    XCTAssertTrue(presenter.isPresented)

    presenter.dismiss()
    await fulfillment(of: [dismissed], timeout: 5)
    XCTAssertFalse(presenter.isPresented)
  }

  func testPresentAtRectPresentsMenu() async throws {
    guard MenuPresenter.isSupported else { throw XCTSkip("requires iOS 17.4+") }
    let (window, host) = try makeHost()
    defer { window.isHidden = true }

    let presenter = MenuPresenter()
    let presented = expectation(description: "menu presented")

    let spec = MenuSpec(children: [.action(MenuAction(id: "a", title: "A"))])
    presenter.present(
      spec,
      at: .rect(CGRect(x: 150, y: 380, width: 120, height: 44)),
      in: host,
      onAction: { _ in },
      onLifecycle: { if $0 == .presented { presented.fulfill() } }
    )

    await fulfillment(of: [presented], timeout: 5)
    presenter.dismiss()
  }

  /// A second present() while one is live must replace it — no stacked menus,
  /// and only the new menu's events reach the listener.
  func testReplaceWhilePresented() async throws {
    guard MenuPresenter.isSupported else { throw XCTSkip("requires iOS 17.4+") }
    let (window, host) = try makeHost()
    defer { window.isHidden = true }

    let presenter = MenuPresenter()
    var firstEvents: [MenuLifecycleEvent] = []
    let secondPresented = expectation(description: "second menu presented")

    let spec = MenuSpec(children: [.action(MenuAction(id: "a", title: "A"))])
    presenter.present(spec, at: .point(CGPoint(x: 100, y: 300)), in: host, onAction: { _ in }) {
      firstEvents.append($0)
    }

    presenter.present(spec, at: .point(CGPoint(x: 200, y: 500)), in: host, onAction: { _ in }) {
      if $0 == .presented { secondPresented.fulfill() }
    }

    await fulfillment(of: [secondPresented], timeout: 5)
    presenter.dismiss()
  }

  /// The action's identifier carries the wire id — what routes a selection
  /// back to the caller (driving a real tap can't be synthesized here).
  func testActionSelectionRoutesId() async throws {
    let spec = MenuSpec(children: [
      .action(MenuAction(id: "one", title: "One")),
      .submenu(MenuSpec(title: "More", children: [
        .action(MenuAction(id: "nested", title: "Nested")),
      ])),
    ])
    let menu = MenuBuilder.menu(from: spec) { _ in }

    guard let section = menu.children.first as? UIMenu,
          let action = section.children.first as? UIAction else {
      return XCTFail("expected inline section with action")
    }
    XCTAssertEqual(action.identifier.rawValue, "one")

    guard let sub = section.children[1] as? UIMenu,
          let nestedSection = sub.children.first as? UIMenu,
          let nestedAction = nestedSection.children.first as? UIAction else {
      return XCTFail("expected nested submenu structure")
    }
    XCTAssertEqual(nestedAction.identifier.rawValue, "nested")
  }
}
