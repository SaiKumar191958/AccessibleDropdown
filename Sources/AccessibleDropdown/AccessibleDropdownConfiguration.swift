//
//  File.swift
//  AccessibleDropdown
//
//  Created by Sai Babu on 06/04/26.
//

import UIKit

// MARK: - ExpansionStyle
/// Controls how the dropdown menu appears when opened.
///
/// App developers choose one of these two modes:
///
///  .overlay  — The menu floats on top of everything below it.
///              Nothing moves. Ideal when space is tight.
///
///  .inline   — The menu expands inside the SwiftUI / UIKit layout,
///              pushing sibling views downward. The parent container
///              grows to accommodate the open menu.
///
public enum DropdownExpansionStyle {
    /// Menu floats above sibling views in the UIWindow layer.
    case overlay
    /// Menu expands inline, pushing sibling views down.
    case inline
}

// MARK: - AccessibleDropdownTheme
/// Complete visual theme. All colours, fonts, sizes and spacing in one place.
/// Build a theme once and reuse it across every dropdown in the app.
///
/// ```swift
/// // App-level theme (e.g. in a ThemeManager or extension)
/// extension AccessibleDropdownTheme {
///     static let carelon = AccessibleDropdownTheme(
///         triggerBackground : UIColor(named: "BrandSurface")!,
///         triggerBorder     : UIColor(named: "BrandPurple")!,
///         triggerText       : .label,
///         placeholder       : .placeholderText,
///         fieldLabel        : UIColor(named: "BrandPurple")!,
///         menuBackground    : .systemBackground,
///         optionText        : .label,
///         optionSubtitle    : .secondaryLabel,
///         optionSelectedBg  : UIColor(named: "BrandPurple")!.withAlphaComponent(0.12),
///         optionSelectedText: UIColor(named: "BrandPurple")!,
///         optionDisabledText: .tertiaryLabel,
///         chevron           : UIColor(named: "BrandPurple")!,
///         separator         : .separator,
///         triggerFont       : UIFont(name: "AvenirNext-Medium", size: 16)!,
///         optionFont        : UIFont(name: "AvenirNext-Regular", size: 15)!,
///         subtitleFont      : UIFont(name: "AvenirNext-Regular", size: 12)!,
///         fieldLabelFont    : UIFont(name: "AvenirNext-DemiBold", size: 12)!,
///         triggerHeight     : 50,
///         optionRowHeight   : 52,
///         cornerRadius      : 12,
///         borderWidth       : 1.5,
///         maxVisibleRows    : 6,
///         animationDuration : 0.2
///     )
/// }
/// ```
public struct AccessibleDropdownTheme {

    // MARK: Colours — Trigger
    public var triggerBackground:   UIColor
    public var triggerBorder:       UIColor
    public var triggerText:         UIColor
    public var placeholder:         UIColor
    public var fieldLabel:          UIColor

    // MARK: Colours — Menu
    public var menuBackground:      UIColor
    public var optionText:          UIColor
    public var optionSubtitle:      UIColor
    public var optionSelectedBg:    UIColor
    public var optionSelectedText:  UIColor
    public var optionDisabledText:  UIColor
    public var chevron:             UIColor
    public var separator:           UIColor

    // MARK: Typography
    public var triggerFont:         UIFont
    public var optionFont:          UIFont
    public var subtitleFont:        UIFont
    public var fieldLabelFont:      UIFont

    // MARK: Sizing
    /// Minimum height of the trigger row. Will grow if font size requires it.
    public var triggerHeight:       CGFloat
    /// Minimum height of each option row. Will grow if content requires it.
    public var optionRowHeight:     CGFloat
    public var cornerRadius:        CGFloat
    public var borderWidth:         CGFloat
    public var maxVisibleRows:      Int

    // MARK: Animation
    public var animationDuration:   TimeInterval

    // MARK: Init — all params optional, sensible HIG defaults built-in
    public init(
        triggerBackground:   UIColor       = .secondarySystemBackground,
        triggerBorder:       UIColor       = .separator,
        triggerText:         UIColor       = .label,
        placeholder:         UIColor       = .placeholderText,
        fieldLabel:          UIColor       = .secondaryLabel,
        menuBackground:      UIColor       = .secondarySystemBackground,
        optionText:          UIColor       = .label,
        optionSubtitle:      UIColor       = .secondaryLabel,
        optionSelectedBg:    UIColor       = UIColor.systemBlue.withAlphaComponent(0.12),
        optionSelectedText:  UIColor       = .systemBlue,
        optionDisabledText:  UIColor       = .tertiaryLabel,
        chevron:             UIColor       = .secondaryLabel,
        separator:           UIColor       = .separator,
        triggerFont:         UIFont        = .preferredFont(forTextStyle: .body),
        optionFont:          UIFont        = .preferredFont(forTextStyle: .body),
        subtitleFont:        UIFont        = .preferredFont(forTextStyle: .caption1),
        fieldLabelFont:      UIFont        = .preferredFont(forTextStyle: .caption2),
        triggerHeight:       CGFloat       = 44,
        optionRowHeight:     CGFloat       = 48,
        cornerRadius:        CGFloat       = 10,
        borderWidth:         CGFloat       = 1,
        maxVisibleRows:      Int           = 5,
        animationDuration:   TimeInterval  = 0.22
    ) {
        self.triggerBackground  = triggerBackground
        self.triggerBorder      = triggerBorder
        self.triggerText        = triggerText
        self.placeholder        = placeholder
        self.fieldLabel         = fieldLabel
        self.menuBackground     = menuBackground
        self.optionText         = optionText
        self.optionSubtitle     = optionSubtitle
        self.optionSelectedBg   = optionSelectedBg
        self.optionSelectedText = optionSelectedText
        self.optionDisabledText = optionDisabledText
        self.chevron            = chevron
        self.separator          = separator
        self.triggerFont        = triggerFont
        self.optionFont         = optionFont
        self.subtitleFont       = subtitleFont
        self.fieldLabelFont     = fieldLabelFont
        self.triggerHeight      = triggerHeight
        self.optionRowHeight    = optionRowHeight
        self.cornerRadius       = cornerRadius
        self.borderWidth        = borderWidth
        self.maxVisibleRows     = maxVisibleRows
        self.animationDuration  = animationDuration
    }

    /// Default HIG-compliant theme.
    public static let `default` = AccessibleDropdownTheme()
}

// MARK: - AccessibleDropdownConfiguration
/// Combines the visual theme with behaviour settings and accessibility strings.
/// This is the single object you pass to the dropdown.
public struct AccessibleDropdownConfiguration {

    // MARK: Theme
    /// Full visual theme. Swap this to completely restyle the dropdown.
    public var theme: AccessibleDropdownTheme = .default

    // MARK: Behaviour
    /// How the menu appears. `.overlay` floats above siblings;
    /// `.inline` pushes siblings down. Default: `.overlay`.
    public var expansionStyle: DropdownExpansionStyle = .overlay

    /// When true a shadow is drawn under the floating menu card.
    /// Only applies when `expansionStyle == .overlay`.
    public var showMenuShadow: Bool = true

    /// Shadow colour (overlay mode only).
    public var menuShadowColor: UIColor = UIColor.black.withAlphaComponent(0.15)

    /// Shadow radius (overlay mode only).
    public var menuShadowRadius: CGFloat = 8

    // MARK: Accessibility strings — localise these for each language
    public var collapsedHint:          String = "Expands the list of options."
    public var expandedHint:           String = "Collapses the list of options."
    public var selectedSuffix:         String = "selected"
    public var menuOpenedAnnouncement: String = "Options menu expanded."
    public var menuClosedAnnouncement: String = "Options menu collapsed."

    // MARK: Init
    public init() {}

    // MARK: Convenience builders

    /// Create a configuration with a custom theme, keeping default behaviour.
    public static func themed(_ theme: AccessibleDropdownTheme) -> Self {
        var c = AccessibleDropdownConfiguration()
        c.theme = theme
        return c
    }

    /// Create a configuration with a specific expansion style, keeping default theme.
    public static func style(_ style: DropdownExpansionStyle) -> Self {
        var c = AccessibleDropdownConfiguration()
        c.expansionStyle = style
        return c
    }

    /// Create a configuration with both a theme and an expansion style.
    public static func themed(
        _ theme: AccessibleDropdownTheme,
        expansionStyle: DropdownExpansionStyle
    ) -> Self {
        var c = AccessibleDropdownConfiguration()
        c.theme = theme
        c.expansionStyle = expansionStyle
        return c
    }
}

// MARK: - Convenience back-compat shims
// So any code using the old flat property names still compiles.
public extension AccessibleDropdownConfiguration {
    var triggerBackgroundColor:       UIColor { theme.triggerBackground }
    var triggerBorderColor:           UIColor { theme.triggerBorder }
    var triggerTextColor:             UIColor { theme.triggerText }
    var placeholderColor:             UIColor { theme.placeholder }
    var floatingLabelColor:           UIColor { theme.fieldLabel }
    var menuBackgroundColor:          UIColor { theme.menuBackground }
    var optionTextColor:              UIColor { theme.optionText }
    var optionSubtitleColor:          UIColor { theme.optionSubtitle }
    var optionSelectedBackgroundColor:UIColor { theme.optionSelectedBg }
    var optionSelectedTextColor:      UIColor { theme.optionSelectedText }
    var optionDisabledTextColor:      UIColor { theme.optionDisabledText }
    var chevronTintColor:             UIColor { theme.chevron }
    var separatorColor:               UIColor { theme.separator }
    var triggerFont:                  UIFont  { theme.triggerFont }
    var optionTitleFont:              UIFont  { theme.optionFont }
    var optionSubtitleFont:           UIFont  { theme.subtitleFont }
    var floatingLabelFont:            UIFont  { theme.fieldLabelFont }
    var triggerMinHeight:             CGFloat { theme.triggerHeight }
    var optionRowHeight:              CGFloat { theme.optionRowHeight }
    var cornerRadius:                 CGFloat { theme.cornerRadius }
    var maxVisibleRows:               Int     { theme.maxVisibleRows }
    var animationDuration:            TimeInterval { theme.animationDuration }
}
