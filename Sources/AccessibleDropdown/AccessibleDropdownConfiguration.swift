//
//  File.swift
//  AccessibleDropdown
//
//  Created by Sai Babu on 06/04/26.
//

import UIKit

// MARK: - AccessibleDropdownConfiguration
/// All visual and accessibility tunables for AccessibleDropdown.
/// Pass a customised instance to the initialiser; defaults follow
/// Apple Human Interface Guidelines throughout.
public struct AccessibleDropdownConfiguration {

    // MARK: Dimensions

    /// Minimum height of the trigger button — HIG recommends 44 pt.
    public var triggerMinHeight: CGFloat = 44

    /// Height of each option row in the expanded menu.
    public var optionRowHeight: CGFloat = 48

    /// Maximum number of visible rows before the menu scrolls.
    public var maxVisibleRows: Int = 5

    /// Corner radius applied to both the trigger and the menu card.
    public var cornerRadius: CGFloat = 10

    // MARK: Typography

    /// Font for the currently selected value shown on the trigger.
    public var triggerFont: UIFont = .preferredFont(forTextStyle: .body)

    /// Font for each option's title label.
    public var optionTitleFont: UIFont = .preferredFont(forTextStyle: .body)

    /// Font for each option's optional subtitle label.
    public var optionSubtitleFont: UIFont = .preferredFont(forTextStyle: .caption1)

    /// Font for the floating label that sits above the trigger.
    public var floatingLabelFont: UIFont = .preferredFont(forTextStyle: .caption2)

    // MARK: Colours

    public var triggerBackgroundColor: UIColor = .secondarySystemBackground
    public var triggerBorderColor: UIColor = .separator
    public var triggerTextColor: UIColor = .label
    public var placeholderColor: UIColor = .placeholderText
    public var floatingLabelColor: UIColor = .secondaryLabel
    public var menuBackgroundColor: UIColor = .secondarySystemBackground
    public var optionTextColor: UIColor = .label
    public var optionSubtitleColor: UIColor = .secondaryLabel
    public var optionSelectedBackgroundColor: UIColor = .systemBlue.withAlphaComponent(0.12)
    public var optionSelectedTextColor: UIColor = .systemBlue
    public var optionDisabledTextColor: UIColor = .tertiaryLabel
    public var chevronTintColor: UIColor = .secondaryLabel
    public var separatorColor: UIColor = .separator

    // MARK: Accessibility Strings
    // These are the strings VoiceOver will speak. Localise as needed.

    /// Spoken when the dropdown has no selection yet.
    public var placeholderAccessibilityLabel: String = "Select an option"

    /// Spoken after the field label when the menu is closed.
    /// e.g. "Country, collapsed, double tap to expand"
    public var collapsedHint: String = "Double tap to expand options."

    /// Spoken after the field label when the menu is open.
    public var expandedHint: String = "Double tap to collapse options."

    /// Appended to each option's label when that option is currently selected.
    /// e.g. "India, selected"
    public var selectedSuffix: String = "selected"

    /// Announcement posted via UIAccessibilityLayoutChangedNotification
    /// when the menu opens.
    public var menuOpenedAnnouncement: String = "Menu expanded."

    /// Announcement posted when the menu closes.
    public var menuClosedAnnouncement: String = "Menu collapsed."

    // MARK: Animation

    /// Duration of the expand/collapse animation in seconds.
    public var animationDuration: TimeInterval = 0.22

    // MARK: Init

    public init() {}
}
