import UIKit
import XCTest

@testable import LiquidMenu

/// Builder-level coverage: MenuSpec → UIMenu structure, attributes, options.
/// Runs without a window — pure model-to-UIKit mapping.
@MainActor
final class MenuBuilderTests: XCTestCase {

  private func build(_ spec: MenuSpec) -> UIMenu {
    MenuBuilder.menu(from: spec) { _ in }
  }

  /// The builder wraps each contiguous run in a `.displayInline` section —
  /// flatten the root's children into the actions they contain.
  private func actions(in menu: UIMenu) -> [UIAction] {
    menu.children.flatMap { child -> [UIAction] in
      if let action = child as? UIAction { return [action] }
      if let section = child as? UIMenu {
        return section.children.compactMap { $0 as? UIAction }
      }
      return []
    }
  }

  private func topLevelMenus(in menu: UIMenu) -> [UIMenu] {
    menu.children.compactMap { $0 as? UIMenu }
  }

  // ─── Structure ───

  func testFlatActionsBecomeOneInlineRun() {
    let menu = build(MenuSpec(children: [
      .action(MenuAction(id: "a", title: "A")),
      .action(MenuAction(id: "b", title: "B")),
    ]))
    let sections = topLevelMenus(in: menu)
    XCTAssertEqual(sections.count, 1)
    XCTAssertTrue(sections[0].options.contains(.displayInline))
    XCTAssertEqual(actions(in: menu).map(\.title), ["A", "B"])
  }

  func testDividersSplitChildrenIntoInlineSections() {
    let menu = build(MenuSpec(children: [
      .action(MenuAction(id: "a", title: "A")),
      .divider,
      .action(MenuAction(id: "b", title: "B")),
      .divider,
      .action(MenuAction(id: "c", title: "C")),
    ]))
    let sections = topLevelMenus(in: menu)
    XCTAssertEqual(sections.count, 3)
    XCTAssertTrue(sections.allSatisfy { $0.options.contains(.displayInline) })
    XCTAssertEqual(actions(in: sections[0]).map(\.title), ["A"])
    XCTAssertEqual(actions(in: sections[2]).map(\.title), ["C"])
  }

  func testEdgeDividersAreTrimmed() {
    let menu = build(MenuSpec(children: [
      .divider,
      .action(MenuAction(id: "a", title: "A")),
      .divider,
    ]))
    XCTAssertEqual(topLevelMenus(in: menu).count, 1)
    XCTAssertEqual(actions(in: menu).map(\.title), ["A"])
  }

  func testExplicitSectionKeepsTitleAndOptions() {
    let menu = build(MenuSpec(children: [
      .section(MenuSpec(
        title: "Group",
        options: MenuOptions(singleSelection: true),
        children: [.action(MenuAction(id: "a", title: "A"))]
      )),
    ]))
    let section = topLevelMenus(in: menu).first
    XCTAssertEqual(section?.title, "Group")
    XCTAssertTrue(section?.options.contains(.singleSelection) ?? false)
    XCTAssertTrue(section?.options.contains(.displayInline) ?? false)
  }

  func testSubmenuIsNavigableNotInline() {
    let menu = build(MenuSpec(children: [
      .submenu(MenuSpec(title: "More", children: [
        .action(MenuAction(id: "a", title: "A"))
      ])),
    ]))
    // The submenu sits inside the enclosing inline run.
    let submenu = topLevelMenus(in: topLevelMenus(in: menu).first ?? UIMenu()).first
    XCTAssertEqual(submenu?.title, "More")
    XCTAssertFalse(submenu?.options.contains(.displayInline) ?? true)
  }

  func testDeferredBecomesDeferredElement() {
    let menu = build(MenuSpec(children: [
      .deferred(MenuDeferred(id: "d") { [] }),
    ]))
    let inner = topLevelMenus(in: menu).first
    XCTAssertTrue(inner?.children.first is UIDeferredMenuElement)
  }

  // ─── Action attributes ───

  func testActionAttributes() {
    let menu = build(MenuSpec(children: [
      .action(MenuAction(
        id: "a", title: "A",
        isDestructive: true, isDisabled: true, isHidden: false,
        keepsMenuPresented: true)),
    ]))
    let action = actions(in: menu).first!
    XCTAssertTrue(action.attributes.contains(.destructive))
    XCTAssertTrue(action.attributes.contains(.disabled))
    XCTAssertTrue(action.attributes.contains(.keepsMenuPresented))
    XCTAssertFalse(action.attributes.contains(.hidden))
  }

  func testActionStates() {
    let menu = build(MenuSpec(children: [
      .action(MenuAction(id: "a", title: "A", state: .on)),
      .action(MenuAction(id: "b", title: "B", state: .mixed)),
    ]))
    let acts = actions(in: menu)
    XCTAssertEqual(acts[0].state, .on)
    XCTAssertEqual(acts[1].state, .mixed)
  }

  func testDiscoverabilityTitlePropagates() {
    let menu = build(MenuSpec(children: [
      .action(MenuAction(id: "a", title: "A", discoverabilityTitle: "Tap A")),
    ]))
    XCTAssertEqual(actions(in: menu).first?.discoverabilityTitle, "Tap A")
  }

  /// The action's identifier carries the wire id — that is what routes the
  /// selection event back to Dart.
  func testActionIdentifierCarriesWireId() {
    let menu = build(MenuSpec(children: [
      .action(MenuAction(id: "pick-me", title: "Pick")),
    ]))
    XCTAssertEqual(actions(in: menu).first?.identifier.rawValue, "pick-me")
  }

  // ─── Menu-level ───

  func testMenuIdentifierAndTitle() {
    let menu = build(MenuSpec(title: "Root", identifier: "root", children: []))
    XCTAssertEqual(menu.title, "Root")
    XCTAssertEqual(menu.identifier, UIMenu.Identifier("root"))
  }

  func testPreferredElementSize() {
    let menu = build(MenuSpec(preferredElementSize: .small, children: [
      .action(MenuAction(id: "a", title: "A")),
    ]))
    XCTAssertEqual(menu.preferredElementSize, .small)
  }

  func testSFSymbolIconProducesImage() {
    let menu = build(MenuSpec(children: [
      .action(MenuAction(
        id: "a", title: "A",
        image: .sfSymbol(SFSymbolIcon(name: "star.fill")))),
    ]))
    XCTAssertNotNil(actions(in: menu).first?.image)
  }

  func testUnknownSymbolNameDoesNotCrash() {
    let menu = build(MenuSpec(children: [
      .action(MenuAction(
        id: "a", title: "A",
        image: .sfSymbol(SFSymbolIcon(name: "not.a.symbol")))),
    ]))
    // UIImage(systemName:) may return nil for unknown names — either way the
    // builder must not crash and the action must exist.
    XCTAssertEqual(actions(in: menu).count, 1)
  }

  func testImageIconRoundTrip() {
    let image = UIImage(systemName: "star")!
    let menu = build(MenuSpec(children: [
      .action(MenuAction(id: "a", title: "A", image: .image(image, templated: false))),
    ]))
    XCTAssertNotNil(actions(in: menu).first?.image)
  }
}
