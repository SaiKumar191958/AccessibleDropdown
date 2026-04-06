//
//  File.swift
//  AccessibleDropdown
//
//  Created by Sai Babu on 06/04/26.
//

import UIKit

// MARK: - AccessibleDropdownOptionCell
/// A UITableViewCell subclass that represents one option in the
/// expanded dropdown menu.
///
/// Accessibility implementation:
/// - isAccessibilityElement = true (the cell is the single focusable unit)
/// - accessibilityTraits    = .button (always) | .notEnabled (when disabled)
///   The .selected trait is added when this option equals the current selection.
/// - accessibilityLabel     = "[title], [subtitle]"  (subtitle only if present)
/// - accessibilityValue     = "selected"  when this is the chosen option
///
final class AccessibleDropdownOptionCell: UITableViewCell {

    static let reuseIdentifier = "AccessibleDropdownOptionCell"

    // MARK: Subviews

    private let iconView: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.contentMode = .scaleAspectFit
        iv.tintColor = .label
        // Icon is decorative — hide from VoiceOver so the cell label
        // carries all meaning.
        iv.isAccessibilityElement = false
        iv.accessibilityElementsHidden = true
        return iv
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.adjustsFontForContentSizeCategory = true  // Dynamic Type
        l.numberOfLines = 0
        return l
    }()

    private let subtitleLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.adjustsFontForContentSizeCategory = true
        l.numberOfLines = 0
        return l
    }()

    private let checkmarkView: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.image = UIImage(systemName: "checkmark")
        iv.contentMode = .scaleAspectFit
        iv.isAccessibilityElement = false
        iv.accessibilityElementsHidden = true
        iv.isHidden = true
        return iv
    }()

    private var iconWidthConstraint: NSLayoutConstraint!

    // MARK: Init

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    // MARK: Setup

    private func setup() {
        selectionStyle = .none
        backgroundColor = .clear

        // The cell itself is the single accessibility element — suppress
        // children so VoiceOver does not descend into subviews.
        isAccessibilityElement = true
        accessibilityTraits = .button

        let textStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        textStack.translatesAutoresizingMaskIntoConstraints = false
        textStack.axis = .vertical
        textStack.spacing = 2
        textStack.alignment = .leading

        contentView.addSubview(iconView)
        contentView.addSubview(textStack)
        contentView.addSubview(checkmarkView)

        iconWidthConstraint = iconView.widthAnchor.constraint(equalToConstant: 0)

        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            iconView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            iconView.heightAnchor.constraint(equalToConstant: 22),
            iconWidthConstraint,

            textStack.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 0),
            textStack.trailingAnchor.constraint(equalTo: checkmarkView.leadingAnchor, constant: -8),
            textStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            textStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),

            checkmarkView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            checkmarkView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            checkmarkView.widthAnchor.constraint(equalToConstant: 18),
            checkmarkView.heightAnchor.constraint(equalToConstant: 18)
        ])
    }

    // MARK: Configure

    func configure(
        with option: AccessibleDropdownOption,
        isSelected: Bool,
        config: AccessibleDropdownConfiguration
    ) {
        // --- Visual ---
        titleLabel.text = option.title
        titleLabel.font = config.optionTitleFont
        titleLabel.textColor = option.isDisabled
            ? config.optionDisabledTextColor
            : (isSelected ? config.optionSelectedTextColor : config.optionTextColor)

        subtitleLabel.text = option.subtitle
        subtitleLabel.font = config.optionSubtitleFont
        subtitleLabel.textColor = config.optionSubtitleColor
        subtitleLabel.isHidden = option.subtitle == nil

        if let iconName = option.iconName {
            iconView.image = UIImage(systemName: iconName)
            iconView.tintColor = option.isDisabled
                ? config.optionDisabledTextColor
                : config.optionTextColor
            iconWidthConstraint.constant = 24
            // Add spacing between icon and text
            iconView.trailingAnchor
                .constraint(equalTo: iconView.leadingAnchor, constant: 24)
                .isActive = false
            (iconView.superview?.subviews[1] as? UIStackView)?
                .leadingAnchor
                .constraint(equalTo: iconView.trailingAnchor, constant: 12)
                .isActive = true
        } else {
            iconView.image = nil
            iconWidthConstraint.constant = 0
        }

        checkmarkView.isHidden = !isSelected
        checkmarkView.tintColor = config.optionSelectedTextColor

        backgroundColor = isSelected
            ? config.optionSelectedBackgroundColor
            : config.menuBackgroundColor

        isUserInteractionEnabled = !option.isDisabled
        alpha = option.isDisabled ? 0.5 : 1.0

        // --- Accessibility ---
        // Build a rich label: "India, New Delhi" or just "India"
        var a11yLabel = option.title
        if let sub = option.subtitle, !sub.isEmpty {
            a11yLabel += ", \(sub)"
        }
        accessibilityLabel = a11yLabel

        // Value communicates selection state separately from traits
        // so VoiceOver speaks: "India, selected" (value) rather than
        // relying only on the .selected trait checkmark sound.
        accessibilityValue = isSelected ? config.selectedSuffix : nil

        var traits: UIAccessibilityTraits = .button
        if isSelected { traits.insert(.selected) }
        if option.isDisabled { traits.insert(.notEnabled) }
        accessibilityTraits = traits
    }
}
