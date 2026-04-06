// The Swift Programming Language
// https://docs.swift.org/swift-book
import UIKit

// MARK: - AccessibleDropdownDelegate
public protocol AccessibleDropdownDelegate: AnyObject {
    func accessibleDropdown(
        _ dropdown: AccessibleDropdown,
        didSelect option: AccessibleDropdownOption
    )
}

// MARK: - AccessibleDropdown
///
/// Supports two expansion styles set via `configuration.expansionStyle`:
///
///  .overlay  ──────────────────────────────────────────────────────────
///
///   ┌─────────────────┐   Menu is added to UIWindow.
///   │  Label          │   Siblings are NOT moved.
///   │ [ Selected ▾ ]  │   Good for tight layouts.
///   └─────────────────┘
///       ┌─────────────────┐  ← floating in window
///       │  Option A  ✓   │
///       │  Option B      │
///       └─────────────────┘
///   ┌─────────────────┐   ← Phone field stays put
///
///  .inline  ───────────────────────────────────────────────────────────
///
///   ┌─────────────────┐
///   │  Label          │
///   │ [ Selected ▾ ]  │
///   │  Option A  ✓   │  ← menu is a subview; VStack pushes Phone field
///   │  Option B      │    down automatically
///   └─────────────────┘
///   ┌─────────────────┐   ← Phone field pushed down
///
open class AccessibleDropdown: UIControl {

    // MARK: - Public API

    public var fieldLabel: String = "" {
        didSet { fieldLabelView.text = fieldLabel; updateAccessibility() }
    }

    public var placeholder: String = "Select an option" {
        didSet { updateTriggerTitle() }
    }

    public var options: [AccessibleDropdownOption] = [] {
        didSet {
            menuView.options = options
            if configuration.expansionStyle == .inline {
                invalidateIntrinsicContentSize()
            }
        }
    }

    public private(set) var selectedOption: AccessibleDropdownOption? {
        didSet {
            menuView.selectedOption = selectedOption
            updateTriggerTitle()
            updateAccessibility()
        }
    }

    public var onSelect: ((AccessibleDropdownOption) -> Void)?
    public weak var delegate: AccessibleDropdownDelegate?

    public var configuration: AccessibleDropdownConfiguration = .init() {
        didSet { applyConfiguration() }
    }

    public func setSelectedOption(_ option: AccessibleDropdownOption?) {
        selectedOption = option
    }

    public private(set) var isExpanded = false

    // MARK: - Subviews

    private let fieldLabelView: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.adjustsFontForContentSizeCategory = true
        l.isAccessibilityElement = false
        l.accessibilityElementsHidden = true
        return l
    }()

    private let triggerContainer: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.layer.masksToBounds = true
        return v
    }()

    private let triggerValueLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.adjustsFontForContentSizeCategory = true
        l.isAccessibilityElement = false
        return l
    }()

    private let chevronView: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "chevron.down"))
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.contentMode = .scaleAspectFit
        iv.isAccessibilityElement = false
        iv.accessibilityElementsHidden = true
        return iv
    }()

    // Inline menu — lives inside this view's hierarchy
    private let menuView = AccessibleDropdownMenuView()

    // Overlay menu — lives in the UIWindow
    private let overlayMenuView = AccessibleDropdownMenuView()

    // MARK: - Constraints

    private var triggerHeightConstraint: NSLayoutConstraint!

    // Inline mode: menu height animates between 0 and preferredHeight
    private var inlineMenuHeightConstraint: NSLayoutConstraint!

    // MARK: - Init

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
        applyConfiguration()
        updateAccessibility()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
        applyConfiguration()
        updateAccessibility()
    }

    deinit { overlayMenuView.removeFromSuperview() }

    // MARK: - Setup

    private func setup() {
        isAccessibilityElement = true
        accessibilityTraits    = .button

        // Trigger row
        triggerContainer.addSubview(triggerValueLabel)
        triggerContainer.addSubview(chevronView)

        NSLayoutConstraint.activate([
            triggerValueLabel.leadingAnchor.constraint(
                equalTo: triggerContainer.leadingAnchor, constant: 14),
            triggerValueLabel.centerYAnchor.constraint(
                equalTo: triggerContainer.centerYAnchor),
            triggerValueLabel.trailingAnchor.constraint(
                equalTo: chevronView.leadingAnchor, constant: -8),
            chevronView.trailingAnchor.constraint(
                equalTo: triggerContainer.trailingAnchor, constant: -14),
            chevronView.centerYAnchor.constraint(
                equalTo: triggerContainer.centerYAnchor),
            chevronView.widthAnchor.constraint(equalToConstant: 16),
            chevronView.heightAnchor.constraint(equalToConstant: 16)
        ])

        // Inline menu — starts at 0 height, clipped
        menuView.translatesAutoresizingMaskIntoConstraints = false
        menuView.clipsToBounds = true
        menuView.isAccessibilityElement = false

        addSubview(fieldLabelView)
        addSubview(triggerContainer)
        addSubview(menuView)

        triggerHeightConstraint = triggerContainer.heightAnchor.constraint(
            greaterThanOrEqualToConstant: 44)

        inlineMenuHeightConstraint = menuView.heightAnchor.constraint(
            equalToConstant: 0)
        inlineMenuHeightConstraint.priority = .defaultHigh

        NSLayoutConstraint.activate([
            fieldLabelView.topAnchor.constraint(equalTo: topAnchor),
            fieldLabelView.leadingAnchor.constraint(equalTo: leadingAnchor),
            fieldLabelView.trailingAnchor.constraint(equalTo: trailingAnchor),

            triggerContainer.topAnchor.constraint(
                equalTo: fieldLabelView.bottomAnchor, constant: 4),
            triggerContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            triggerContainer.trailingAnchor.constraint(equalTo: trailingAnchor),
            triggerHeightConstraint,

            menuView.topAnchor.constraint(
                equalTo: triggerContainer.bottomAnchor, constant: 0),
            menuView.leadingAnchor.constraint(equalTo: leadingAnchor),
            menuView.trailingAnchor.constraint(equalTo: trailingAnchor),
            menuView.bottomAnchor.constraint(equalTo: bottomAnchor),
            inlineMenuHeightConstraint
        ])

        // Tap only on trigger row
        let tap = UITapGestureRecognizer(target: self, action: #selector(triggerTapped))
        triggerContainer.addGestureRecognizer(tap)
        triggerContainer.isUserInteractionEnabled = true

        // Wire both menus
        for m in [menuView, overlayMenuView] {
            m.onSelect  = { [weak self] opt in self?.commitSelection(opt) }
            m.onDismiss = { [weak self] in self?.collapse(returnFocus: true) }
        }
    }

    // MARK: - Configuration

    private func applyConfiguration() {
        let t = configuration.theme

        fieldLabelView.font              = t.fieldLabelFont
        fieldLabelView.textColor         = t.fieldLabel
        triggerValueLabel.font           = t.triggerFont
        chevronView.tintColor            = t.chevron
        triggerContainer.backgroundColor = t.triggerBackground
        triggerContainer.layer.borderColor  = t.triggerBorder.cgColor
        triggerContainer.layer.borderWidth  = t.borderWidth
        triggerContainer.layer.cornerRadius = t.cornerRadius
        triggerHeightConstraint.constant    = t.triggerHeight

        menuView.configuration        = configuration
        overlayMenuView.configuration = configuration

        updateTriggerTitle()
        invalidateIntrinsicContentSize()
    }

    // MARK: - Trigger display

    private func updateTriggerTitle() {
        if let sel = selectedOption {
            triggerValueLabel.text      = sel.title
            triggerValueLabel.textColor = configuration.theme.triggerText
        } else {
            triggerValueLabel.text      = placeholder
            triggerValueLabel.textColor = configuration.theme.placeholder
        }
    }

    // MARK: - Accessibility

    private func updateAccessibility() {
        accessibilityLabel = fieldLabel.isEmpty ? nil : fieldLabel
        accessibilityValue = selectedOption?.title ?? placeholder
        accessibilityHint  = isExpanded
            ? configuration.expandedHint
            : configuration.collapsedHint
    }

    // MARK: - Expand / Collapse

    @objc private func triggerTapped() {
        isExpanded ? collapse(returnFocus: true) : expand()
        sendActions(for: .valueChanged)
    }

    public func expand() {
        guard !isExpanded else { return }
        isExpanded = true
        updateAccessibility()

        switch configuration.expansionStyle {
        case .overlay:  expandOverlay()
        case .inline:   expandInline()
        }

        UIAccessibility.post(notification: .announcement,
                             argument: configuration.menuOpenedAnnouncement)
    }

    public func collapse(returnFocus: Bool = false) {
        guard isExpanded else { return }
        isExpanded = false
        updateAccessibility()

        switch configuration.expansionStyle {
        case .overlay:  collapseOverlay()
        case .inline:   collapseInline()
        }

        if returnFocus {
            UIAccessibility.post(notification: .layoutChanged, argument: self)
        }
        UIAccessibility.post(notification: .announcement,
                             argument: configuration.menuClosedAnnouncement)
    }

    private func commitSelection(_ option: AccessibleDropdownOption) {
        selectedOption = option
        collapse(returnFocus: true)
        onSelect?(option)
        delegate?.accessibleDropdown(self, didSelect: option)
    }

    // MARK: - Overlay mode

    private func expandOverlay() {
        guard let window = window else { return }

        let triggerRect = triggerContainer.convert(triggerContainer.bounds, to: window)
        let safeBottom  = window.bounds.height - window.safeAreaInsets.bottom - 8
        let available   = safeBottom - (triggerRect.maxY + 4)
        let menuHeight  = min(overlayMenuView.preferredHeight(config: configuration),
                              max(available, 0))

        overlayMenuView.translatesAutoresizingMaskIntoConstraints = true
        overlayMenuView.frame = CGRect(
            x:      triggerRect.minX,
            y:      triggerRect.maxY + 4,
            width:  triggerRect.width,
            height: menuHeight
        )
        overlayMenuView.alpha   = 0
        overlayMenuView.options = options
        overlayMenuView.selectedOption = selectedOption

        window.addSubview(overlayMenuView)

        UIView.animate(withDuration: configuration.animationDuration) {
            self.overlayMenuView.alpha = 1
            self.chevronView.transform = CGAffineTransform(rotationAngle: .pi)
        }
        overlayMenuView.moveFocusToFirstOption()
    }

    private func collapseOverlay() {
        UIView.animate(
            withDuration: configuration.animationDuration,
            animations: {
                self.overlayMenuView.alpha = 0
                self.chevronView.transform = .identity
            },
            completion: { _ in self.overlayMenuView.removeFromSuperview() }
        )
    }

    // MARK: - Inline mode

    private func expandInline() {
        menuView.options        = options
        menuView.selectedOption = selectedOption
        menuView.isHidden       = false

        let targetHeight = menuView.preferredHeight(config: configuration)
        inlineMenuHeightConstraint.constant = 0
        layoutIfNeeded()

        UIView.animate(withDuration: configuration.animationDuration) {
            self.inlineMenuHeightConstraint.constant = targetHeight
            self.chevronView.transform = CGAffineTransform(rotationAngle: .pi)
            // This tells the parent SwiftUI VStack / UIKit superview to resize
            self.invalidateIntrinsicContentSize()
            self.superview?.layoutIfNeeded()
        }
        menuView.moveFocusToFirstOption()
    }

    private func collapseInline() {
        UIView.animate(
            withDuration: configuration.animationDuration,
            animations: {
                self.inlineMenuHeightConstraint.constant = 0
                self.chevronView.transform = .identity
                self.invalidateIntrinsicContentSize()
                self.superview?.layoutIfNeeded()
            },
            completion: { _ in self.menuView.isHidden = true }
        )
    }

    // MARK: - Reposition overlay on rotation

    open override func layoutSubviews() {
        super.layoutSubviews()
        guard isExpanded,
              configuration.expansionStyle == .overlay,
              let window = window else { return }

        let triggerRect = triggerContainer.convert(triggerContainer.bounds, to: window)
        let safeBottom  = window.bounds.height - window.safeAreaInsets.bottom - 8
        let available   = safeBottom - (triggerRect.maxY + 4)
        let menuHeight  = min(overlayMenuView.preferredHeight(config: configuration),
                              max(available, 0))

        UIView.animate(withDuration: 0.15) {
            self.overlayMenuView.frame = CGRect(
                x: triggerRect.minX, y: triggerRect.maxY + 4,
                width: triggerRect.width, height: menuHeight
            )
        }
    }

    // MARK: - Intrinsic size
    // Inline: includes menu height when expanded.
    // Overlay: trigger + label only (menu lives in window).

    open override var intrinsicContentSize: CGSize {
        let labelH   = fieldLabelView.intrinsicContentSize.height + 4
        let triggerH = max(configuration.theme.triggerHeight, 44)
        var total    = labelH + triggerH

        if isExpanded && configuration.expansionStyle == .inline {
            total += menuView.preferredHeight(config: configuration)
        }
        return CGSize(width: UIView.noIntrinsicMetric, height: total)
    }
}
