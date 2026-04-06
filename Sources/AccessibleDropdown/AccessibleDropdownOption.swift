//
//  File.swift
//  AccessibleDropdown
//
//  Created by Sai Babu on 06/04/26.
//

import Foundation

// MARK: - AccessibleDropdownOption
/// A single selectable option inside an AccessibleDropdown.
/// Conforms to Identifiable so it can be used in SwiftUI Lists
/// and to Equatable for selection comparison.
public struct AccessibleDropdownOption: Identifiable, Equatable {

    // MARK: Public Properties

    /// Stable unique identifier — used by UIAccessibilityContainer
    /// to distinguish elements across layout changes.
    public let id: String

    /// The text displayed in the dropdown row and spoken by VoiceOver
    /// as the accessibility label for this option.
    public let title: String

    /// Optional secondary line shown below the title.
    /// Appended to the VoiceOver label with a comma pause:
    /// "[title], [subtitle]".
    public let subtitle: String?

    /// Optional SF Symbol name shown as a leading icon.
    /// When provided, the icon name is NOT read by VoiceOver —
    /// meaning is conveyed entirely through `title`.
    public let iconName: String?

    /// When true the option is rendered but cannot be selected.
    /// VoiceOver announces the .notEnabled trait.
    public let isDisabled: Bool

    // MARK: Init

    public init(
        id: String = UUID().uuidString,
        title: String,
        subtitle: String? = nil,
        iconName: String? = nil,
        isDisabled: Bool = false
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.iconName = iconName
        self.isDisabled = isDisabled
    }
}
