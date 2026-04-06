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
/// v2 Architecture
/// ───────────────
/// The trigger row and the option menu are completely separate views.
///
///  ┌─────────────────────────────┐  ← AccessibleDropdown  (this UIControl)
///  │  Country code label         │    Lives in SwiftUI layout.
///  │  [ India              ▾ ]   │    intrinsicContentSize = label + 44 pt.
///  └─────────────────────────────┘    SwiftUI does NOT need a fixed .frame().
///
///  When the user taps the trigger:
///
///  ┌─────────────────────────────┐  ← AccessibleDropdownMenuView
///  │  India                  ✓  │    Added directly to the UIWindow.
///  │  USA                       │    Positioned via triggerContainer's frame
///  │  UK                        │    converted to window coordinates.
///  └─────────────────────────────┘    Removed from window on collapse.
///
/// Key fixes vs v1
/// ───────────────
/// 1. Menu is a floating window overlay — SwiftUI layout never affected.
/// 2. Tap gesture is on triggerContainer only — not the whole UIControl.
///    (v1's beginTracking fired anywhere inside the control bounds.)
/// 3. VoiceOver: trigger is the single a11y element for the closed state.
///    Once open, each option cell is a separate focusable element.
/// 4. LoginView no longer needs .frame(height: 200) — remove that.
///
open class AccessibleDropdown: UIControl {

    // MARK: - Public API

    public var fieldLabel: String = "" {
        didSet { floatingLabel.text = fieldLabel; updateAccessibility() }
    }

    public var placeholder: String = "Select an option" {
        didSet { updateTriggerTitle() }
    }

    public var options: [AccessibleDropdownOption] = [] {
        didSet { floatingMenu.options = options }
    }

    public private(set) var selectedOption: AccessibleDropdownOption? {
        didSet {
            floatingMenu.selectedOption = selectedOption
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

    // MARK: - Subviews  (trigger only)

    private let floatingLabel: UILabel = {
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
        v.layer.borderWidth = 1
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

    private let chevronImageView: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "chevron.down"))
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.contentMode = .scaleAspectFit
        iv.isAccessibilityElement = false
        iv.accessibilityElementsHidden = true
        return iv
    }()

    // MARK: - Floating menu (attached to UIWindow when open)

    private let floatingMenu = AccessibleDropdownMenuView()

    // MARK: - Constraints

    private var triggerHeightConstraint: NSLayoutConstraint!

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

    deinit { floatingMenu.removeFromSuperview() }

    // MARK: - Setup

    private func setup() {
        isAccessibilityElement = true
        accessibilityTraits    = .button

        // Trigger row layout
        triggerContainer.addSubview(triggerValueLabel)
        triggerContainer.addSubview(chevronImageView)

        NSLayoutConstraint.activate([
            triggerValueLabel.leadingAnchor.constraint(
                equalTo: triggerContainer.leadingAnchor, constant: 14),
            triggerValueLabel.centerYAnchor.constraint(
                equalTo: triggerContainer.centerYAnchor),
            triggerValueLabel.trailingAnchor.constraint(
                equalTo: chevronImageView.leadingAnchor, constant: -8),

            chevronImageView.trailingAnchor.constraint(
                equalTo: triggerContainer.trailingAnchor, constant: -14),
            chevronImageView.centerYAnchor.constraint(
                equalTo: triggerContainer.centerYAnchor),
            chevronImageView.widthAnchor.constraint(equalToConstant: 16),
            chevronImageView.heightAnchor.constraint(equalToConstant: 16)
        ])

        addSubview(floatingLabel)
        addSubview(triggerContainer)

        triggerHeightConstraint = triggerContainer.heightAnchor.constraint(
            greaterThanOrEqualToConstant: 44)

        NSLayoutConstraint.activate([
            floatingLabel.topAnchor.constraint(equalTo: topAnchor),
            floatingLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            floatingLabel.trailingAnchor.constraint(equalTo: trailingAnchor),

            triggerContainer.topAnchor.constraint(
                equalTo: floatingLabel.bottomAnchor, constant: 4),
            triggerContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            triggerContainer.trailingAnchor.constraint(equalTo: trailingAnchor),
            // Trigger bottom pins the control's bottom — no menu below this view
            triggerContainer.bottomAnchor.constraint(equalTo: bottomAnchor),
            triggerHeightConstraint
        ])

        // ── Tap only on the trigger row ──
        // Using a gesture recogniser instead of beginTracking/endTracking
        // so taps inside the floating menu (which is outside this view's bounds)
        // never accidentally toggle the dropdown.
        let tap = UITapGestureRecognizer(target: self, action: #selector(triggerTapped))
        triggerContainer.addGestureRecognizer(tap)

        // Floating menu callbacks
        floatingMenu.onSelect = { [weak self] option in
            self?.commitSelection(option)
        }
        floatingMenu.onDismiss = { [weak self] in
            // User tapped outside the menu
            self?.collapse(returnFocus: true)
        }
    }

    // MARK: - Configuration theming

    private func applyConfiguration() {
        let c = configuration

        floatingLabel.font      = c.floatingLabelFont
        floatingLabel.textColor = c.floatingLabelColor

        triggerValueLabel.font  = c.triggerFont
        chevronImageView.tintColor = c.chevronTintColor

        triggerContainer.backgroundColor      = c.triggerBackgroundColor
        triggerContainer.layer.borderColor    = c.triggerBorderColor.cgColor
        triggerContainer.layer.cornerRadius   = c.cornerRadius

        triggerHeightConstraint.constant = c.triggerMinHeight
        floatingMenu.configuration       = c
        updateTriggerTitle()
    }

    // MARK: - Trigger title & accessibility

    private func updateTriggerTitle() {
        if let sel = selectedOption {
            triggerValueLabel.text      = sel.title
            triggerValueLabel.textColor = configuration.triggerTextColor
        } else {
            triggerValueLabel.text      = placeholder
            triggerValueLabel.textColor = configuration.placeholderColor
        }
    }

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

    /// Opens the floating menu positioned directly below the trigger.
    public func expand() {
        guard !isExpanded, let window = window else { return }
        isExpanded = true

        // Convert trigger frame to window coordinates
        let triggerInWindow = triggerContainer.convert(
            triggerContainer.bounds, to: window)

        // Max height: space between trigger bottom and safe-area bottom
        let safeBottom = window.bounds.height - window.safeAreaInsets.bottom - 8
        let availableHeight = safeBottom - (triggerInWindow.maxY + 4)
        let menuHeight = min(floatingMenu.preferredHeight, max(availableHeight, 0))

        let menuFrame = CGRect(
            x:      triggerInWindow.minX,
            y:      triggerInWindow.maxY + 4,
            width:  triggerInWindow.width,
            height: menuHeight
        )

        floatingMenu.translatesAutoresizingMaskIntoConstraints = true
        floatingMenu.frame = menuFrame
        floatingMenu.alpha = 0
        floatingMenu.options        = options
        floatingMenu.selectedOption = selectedOption
        window.addSubview(floatingMenu)

        updateAccessibility()

        UIView.animate(withDuration: configuration.animationDuration) {
            self.floatingMenu.alpha = 1
            self.chevronImageView.transform = CGAffineTransform(rotationAngle: .pi)
        }

        UIAccessibility.post(notification: .announcement,
                             argument: configuration.menuOpenedAnnouncement)
        floatingMenu.moveFocusToFirstOption()
    }

    /// Closes the floating menu.
    public func collapse(returnFocus: Bool = false) {
        guard isExpanded else { return }
        isExpanded = false

        UIView.animate(
            withDuration: configuration.animationDuration,
            animations: {
                self.floatingMenu.alpha = 0
                self.chevronImageView.transform = .identity
            },
            completion: { _ in self.floatingMenu.removeFromSuperview() }
        )

        updateAccessibility()

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

    // MARK: - Reposition on rotation

    open override func layoutSubviews() {
        super.layoutSubviews()
        guard isExpanded, let window = window else { return }

        let triggerInWindow = triggerContainer.convert(
            triggerContainer.bounds, to: window)
        let safeBottom = window.bounds.height - window.safeAreaInsets.bottom - 8
        let availableHeight = safeBottom - (triggerInWindow.maxY + 4)
        let menuHeight = min(floatingMenu.preferredHeight, max(availableHeight, 0))

        UIView.animate(withDuration: 0.15) {
            self.floatingMenu.frame = CGRect(
                x:      triggerInWindow.minX,
                y:      triggerInWindow.maxY + 4,
                width:  triggerInWindow.width,
                height: menuHeight
            )
        }
    }

    // MARK: - Intrinsic size  (trigger + label only, no menu contribution)

    open override var intrinsicContentSize: CGSize {
        let labelH   = floatingLabel.intrinsicContentSize.height + 4
        let triggerH = max(configuration.triggerMinHeight, 44)
        return CGSize(width: UIView.noIntrinsicMetric, height: labelH + triggerH)
    }
}
