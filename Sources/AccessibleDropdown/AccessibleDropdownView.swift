//
//  File.swift
//  AccessibleDropdown
//
//  Created by Sai Babu on 06/04/26.
//

import SwiftUI

// MARK: - AccessibleDropdownView
/// SwiftUI wrapper around AccessibleDropdown (UIKit).
/// Fully compatible with SwiftUI's accessibility modifiers.
///
/// ## Usage
/// ```swift
/// @State private var selected: AccessibleDropdownOption?
///
/// let countries = [
///     AccessibleDropdownOption(title: "India"),
///     AccessibleDropdownOption(title: "USA"),
///     AccessibleDropdownOption(title: "UK")
/// ]
///
/// AccessibleDropdownView(
///     label: "Country",
///     placeholder: "Select a country",
///     options: countries,
///     selected: $selected
/// )
/// .frame(height: 80)
/// ```
@available(iOS 14.0, *)
public struct AccessibleDropdownView: UIViewRepresentable {

    // MARK: Properties

    public let label: String
    public let placeholder: String
    public let options: [AccessibleDropdownOption]

    @Binding public var selected: AccessibleDropdownOption?

    public var configuration: AccessibleDropdownConfiguration = .init()
    public var onSelect: ((AccessibleDropdownOption) -> Void)?

    // MARK: Init

    public init(
        label: String,
        placeholder: String = "Select an option",
        options: [AccessibleDropdownOption],
        selected: Binding<AccessibleDropdownOption?>,
        configuration: AccessibleDropdownConfiguration = .init(),
        onSelect: ((AccessibleDropdownOption) -> Void)? = nil
    ) {
        self.label = label
        self.placeholder = placeholder
        self.options = options
        self._selected = selected
        self.configuration = configuration
        self.onSelect = onSelect
    }

    // MARK: UIViewRepresentable

    public func makeUIView(context: Context) -> AccessibleDropdown {
        let dropdown = AccessibleDropdown()
        dropdown.fieldLabel = label
        dropdown.placeholder = placeholder
        dropdown.options = options
        dropdown.configuration = configuration
        dropdown.onSelect = { option in
            selected = option
            onSelect?(option)
        }
        return dropdown
    }

    public func updateUIView(_ uiView: AccessibleDropdown, context: Context) {
        uiView.fieldLabel = label
        uiView.placeholder = placeholder
        uiView.options = options
        uiView.configuration = configuration
        if uiView.selectedOption?.id != selected?.id {
            uiView.setSelectedOption(selected)
        }
    }
}
