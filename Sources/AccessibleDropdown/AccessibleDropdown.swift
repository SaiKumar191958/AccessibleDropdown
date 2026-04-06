// The Swift Programming Language
// https://docs.swift.org/swift-book
import UIKit

// MARK: - AccessibleDropdownDelegate
public protocol AccessibleDropdownDelegate: AnyObject {
    /// Called when the user selects an option.
    func accessibleDropdown(
        _ dropdown: AccessibleDropdown,
        didSelect option: AccessibleDropdownOption
    )
}

// MARK: - AccessibleDropdown
/// A fully accessible dropdown / combo-box control for iOS.
///
/// ## Accessibility features implemented
///
/// 1. **Role** — `accessibilityTraits = .button` on the trigger so
///    VoiceOver announces it as an interactive element.
///
/// 2. **Label** — equals the field label you pass in (e.g. "Country").
///
/// 3. **Value** — equals the currently selected option title, or the
///    placeholder when nothing is selected. VoiceOver speaks:
///    "Country, India, button" or "Country, Select a country, button".
///
/// 4. **Hint** — changes dynamically: "Double tap to expand options."
///    when closed / "Double tap to collapse options." when open.
///
/// 5. **State announcements** — UIAccessibilityLayoutChangedNotification
///    is posted on open (focus moves to first option) and on close
///    (focus returns to the trigger button).
///
/// 6. **Dynamic Type** — all labels use preferredFont(forTextStyle:)
///    and adjustsFontForContentSizeCategory = true.
///
/// 7. **Minimum tap target** — trigger height is enforced at ≥ 44 pt
///    via intrinsicContentSize override.
///
/// 8. **Keyboard / Switch Control** — the trigger and every option
///    row are individually focusable.
///
/// ## Usage
/// ```swift
/// let dropdown = AccessibleDropdown()
/// dropdown.fieldLabel = "Country"
/// dropdown.placeholder = "Select a country"
/// dropdown.options = [
///     AccessibleDropdownOption(title: "India"),
///     AccessibleDropdownOption(title: "USA"),
///     AccessibleDropdownOption(title: "UK")
/// ]
/// dropdown.onSelect = { option in
///     print("Selected:", option.title)
/// }
/// view.addSubview(dropdown)
/// ```
///
open class AccessibleDropdown: UIControl {

    // MARK: Public API

    /// The label shown above the trigger and used as the VoiceOver label.
    public var fieldLabel: String = "" {
        didSet {
            floatingLabel.text = fieldLabel
            // Rebuild a11y label so VoiceOver re-reads on next focus
            updateAccessibility()
        }
    }

    /// Placeholder shown on the trigger when nothing is selected.
    public var placeholder: String = "Select an option" {
        didSet {
            updateTriggerTitle()
            updateAccessibility()
        }
    }

    /// The full list of options available in the menu.
    public var options: [AccessibleDropdownOption] = [] {
        didSet {
            menuView.options = options
            menuView.recalculateHeight()
        }
    }

    /// The currently selected option, if any.
    public private(set) var selectedOption: AccessibleDropdownOption? {
        didSet {
            menuView.selectedOption = selectedOption
            updateTriggerTitle()
            updateAccessibility()
        }
    }

    /// Callback fired whenever the user picks a new option.
    public var onSelect: ((AccessibleDropdownOption) -> Void)?

    /// Delegate alternative to the onSelect closure.
    public weak var delegate: AccessibleDropdownDelegate?

    /// Visual and accessibility configuration. Defaults follow HIG.
    public var configuration: AccessibleDropdownConfiguration = .init() {
        didSet { applyConfiguration() }
    }

    /// Programmatically select an option without firing callbacks.
    public func setSelectedOption(_ option: AccessibleDropdownOption?) {
        selectedOption = option
    }

    // MARK: State

    public private(set) var isExpanded: Bool = false

    // MARK: Subviews

    /// Floating label above the trigger (not an a11y element —
    /// its content is included in the trigger's accessibilityLabel).
    private let floatingLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.adjustsFontForContentSizeCategory = true
        l.isAccessibilityElement = false         // Suppress: trigger owns the label
        l.accessibilityElementsHidden = true
        return l
    }()

    /// The tappable trigger button row.
    private let triggerButton: UIButton = {
        let b = UIButton(type: .custom)
        b.translatesAutoresizingMaskIntoConstraints = false
        // The button is NOT independently accessible —
        // the parent AccessibleDropdown UIControl IS the a11y element.
        b.isAccessibilityElement = false
        b.accessibilityElementsHidden = true
        return b
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

    private let menuView = AccessibleDropdownMenuView()
    private var menuHeightConstraint: NSLayoutConstraint!
    private var triggerHeightConstraint: NSLayoutConstraint!

    // MARK: Init

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        applyConfiguration()
        updateAccessibility()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
        applyConfiguration()
        updateAccessibility()
    }

    // MARK: Setup

    private func setupViews() {
        // -- Accessibility on the control itself --
        // AccessibleDropdown IS the single accessibility element.
        // The trigger, label, and chevron are hidden from VoiceOver.
        isAccessibilityElement = true
        accessibilityTraits = .button

        // -- Trigger container --
        let triggerContainer = UIView()
        triggerContainer.translatesAutoresizingMaskIntoConstraints = false
        triggerContainer.layer.cornerRadius = 10
        triggerContainer.layer.borderWidth = 1
        triggerContainer.layer.masksToBounds = true

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

        // -- Tap gesture on trigger --
        triggerButton.addTarget(self, action: #selector(triggerTapped), for: .touchUpInside)
        triggerContainer.addSubview(triggerButton)
        NSLayoutConstraint.activate([
            triggerButton.topAnchor.constraint(equalTo: triggerContainer.topAnchor),
            triggerButton.bottomAnchor.constraint(equalTo: triggerContainer.bottomAnchor),
            triggerButton.leadingAnchor.constraint(equalTo: triggerContainer.leadingAnchor),
            triggerButton.trailingAnchor.constraint(equalTo: triggerContainer.trailingAnchor)
        ])

        // -- Menu view --
        menuView.translatesAutoresizingMaskIntoConstraints = false
        menuView.alpha = 0
        menuView.isHidden = true
        menuView.onSelect = { [weak self] option in
            self?.selectOption(option)
        }

        // -- Layout: floating label + trigger + menu stacked vertically --
        addSubview(floatingLabel)
        addSubview(triggerContainer)
        addSubview(menuView)

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
            triggerHeightConstraint,

            menuView.topAnchor.constraint(
                equalTo: triggerContainer.bottomAnchor, constant: 4),
            menuView.leadingAnchor.constraint(equalTo: leadingAnchor),
            menuView.trailingAnchor.constraint(equalTo: trailingAnchor),
            menuView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        // Store reference to triggerContainer so applyConfiguration() can theme it
        triggerContainerView = triggerContainer
    }

    // Kept as a stored property so applyConfiguration() can reach it
    private weak var triggerContainerView: UIView?

    // MARK: Configuration Theming

    private func applyConfiguration() {
        let c = configuration

        floatingLabel.font = c.floatingLabelFont
        floatingLabel.textColor = c.floatingLabelColor

        triggerValueLabel.font = c.triggerFont
        chevronImageView.tintColor = c.chevronTintColor

        triggerContainerView?.backgroundColor = c.triggerBackgroundColor
        triggerContainerView?.layer.borderColor = c.triggerBorderColor.cgColor
        triggerContainerView?.layer.cornerRadius = c.cornerRadius

        menuView.configuration = c
        triggerHeightConstraint.constant = c.triggerMinHeight
        updateTriggerTitle()
        updateAccessibility()
    }

    // MARK: Trigger Title

    private func updateTriggerTitle() {
        if let selected = selectedOption {
            triggerValueLabel.text = selected.title
            triggerValueLabel.textColor = configuration.triggerTextColor
        } else {
            triggerValueLabel.text = placeholder
            triggerValueLabel.textColor = configuration.placeholderColor
        }
    }

    // MARK: Accessibility

    private func updateAccessibility() {
        // Label = field name (e.g. "Country")
        accessibilityLabel = fieldLabel.isEmpty ? nil : fieldLabel

        // Value = what is currently chosen (VoiceOver reads label + value together)
        accessibilityValue = selectedOption?.title ?? placeholder

        // Hint changes based on open/closed state
        accessibilityHint = isExpanded
            ? configuration.expandedHint
            : configuration.collapsedHint
    }

    // MARK: Expand / Collapse

    @objc private func triggerTapped() {
        isExpanded ? collapse() : expand()
        sendActions(for: .valueChanged)
    }

    /// Expands the option menu with animation.
    public func expand() {
        guard !isExpanded else { return }
        isExpanded = true

        menuView.options = options
        menuView.selectedOption = selectedOption
        menuView.recalculateHeight()
        menuView.isHidden = false

        UIView.animate(withDuration: configuration.animationDuration) {
            self.menuView.alpha = 1
            self.chevronImageView.transform = CGAffineTransform(rotationAngle: .pi)
            self.layoutIfNeeded()
        }

        updateAccessibility()

        // Notify VoiceOver that layout changed and move focus to first option
        UIAccessibility.post(
            notification: .announcement,
            argument: configuration.menuOpenedAnnouncement
        )
        menuView.moveFocusToFirstOption()
    }

    /// Collapses the option menu with animation.
    public func collapse() {
        guard isExpanded else { return }
        isExpanded = false

        UIView.animate(
            withDuration: configuration.animationDuration,
            animations: {
                self.menuView.alpha = 0
                self.chevronImageView.transform = .identity
                self.layoutIfNeeded()
            },
            completion: { _ in
                self.menuView.isHidden = true
            }
        )

        updateAccessibility()

        // Return VoiceOver focus to the trigger after menu closes
        UIAccessibility.post(
            notification: .layoutChanged,
            argument: self
        )
        UIAccessibility.post(
            notification: .announcement,
            argument: configuration.menuClosedAnnouncement
        )
    }

    // MARK: Selection

    private func selectOption(_ option: AccessibleDropdownOption) {
        selectedOption = option
        collapse()
        onSelect?(option)
        delegate?.accessibleDropdown(self, didSelect: option)
    }

    // MARK: UIControl override — make the whole control tappable

    open override func beginTracking(
        _ touch: UITouch,
        with event: UIEvent?
    ) -> Bool {
        triggerTapped()
        return super.beginTracking(touch, with: event)
    }

    // MARK: Intrinsic size — ensures 44 pt minimum height

    open override var intrinsicContentSize: CGSize {
        let labelH = floatingLabel.intrinsicContentSize.height + 4
        let triggerH = max(configuration.triggerMinHeight, 44)
        return CGSize(width: UIView.noIntrinsicMetric, height: labelH + triggerH)
    }
}
