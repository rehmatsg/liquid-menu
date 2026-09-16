import UIKit

/// The invisible `UIButton` a menu is anchored to and presented through.
///
/// `showsMenuAsPrimaryAction` makes `menu` the button's primary action, so
/// `performPrimaryAction()` (iOS 17.4+) presents it without a real touch —
/// the entire trick: the menu runs the genuine UIKit presentation path,
/// anchored to this button's frame in the window.
final class MenuAnchorControl: UIButton {
  /// Where inside `bounds` the menu attaches; nil defers to the system.
  var attachmentPoint: CGPoint?

  var onWillPresent: (() -> Void)?
  var onWillDismiss: (() -> Void)?

  /// The menu to present — sets `menu`, which `showsMenuAsPrimaryAction`
  /// turns into the primary action.
  var presentedMenu: UIMenu? {
    get { menu }
    set { menu = newValue }
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
    showsMenuAsPrimaryAction = true
    // Never takes real touches: the overlay host is non-interactive, so the
    // button can't be hit even though its own flag stays on — UIKit skips
    // context-menu interaction setup on disabled-interaction controls.
    isOpaque = false
    backgroundColor = .clear
    // No visible chrome — the button exists only to anchor the menu.
    setTitle(nil, for: .normal)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) is not supported")
  }

  /// The menu's attachment point inside `bounds`.
  override func menuAttachmentPoint(for configuration: UIContextMenuConfiguration) -> CGPoint {
    attachmentPoint ?? super.menuAttachmentPoint(for: configuration)
  }

  override func contextMenuInteraction(
    _ interaction: UIContextMenuInteraction,
    willDisplayMenuFor configuration: UIContextMenuConfiguration,
    animator: (any UIContextMenuInteractionAnimating)?
  ) {
    super.contextMenuInteraction(
      interaction,
      willDisplayMenuFor: configuration,
      animator: animator
    )
    onWillPresent?()
  }

  override func contextMenuInteraction(
    _ interaction: UIContextMenuInteraction,
    willEndFor configuration: UIContextMenuConfiguration,
    animator: (any UIContextMenuInteractionAnimating)?
  ) {
    super.contextMenuInteraction(
      interaction,
      willEndFor: configuration,
      animator: animator
    )
    onWillDismiss?()
  }
}
