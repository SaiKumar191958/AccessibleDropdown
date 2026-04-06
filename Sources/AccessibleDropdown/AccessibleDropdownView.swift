//
//  File.swift
//  AccessibleDropdown
//
//  Created by Sai Babu on 06/04/26.
//
import SwiftUI

// MARK: - AccessibleDropdownView
///
/// SwiftUI wrapper for AccessibleDropdown (UIKit).
///
/// ## What changed from v1
///
/// The wrapper no longer needs a fixed `.frame(height:)` in the caller.
/// Because the floating menu lives in the UIWindow (not inside this view),
/// `AccessibleDropdown.intrinsicContentSize` only accounts for the label +
/// trigger row — the SwiftUI layout engine always gets the correct size
/// regardless of whether the menu is open or closed.
///
/// ## Usage in LoginView
/// ```swift
/// // BEFORE (v1) — fixed frame caused clipping / dead space:
/// AccessibleDropdownView(...)
///     .frame(height: 200)   // ← remove this
///
/// // AFTER (v2) — let intrinsicContentSize drive the height:
/// AccessibleDropdownView(
///     label: "Country code",
///     placeholder: "Select country",
///     options: viewModel.dropdownOptions,
///     selected: $selectedCountry
/// )
/// .padding()
/// ```
///
@available(iOS 14.0, *)
public struct AccessibleDropdownView: UIViewRepresentable {

    // MARK: - Properties

    public let label: String
    public let placeholder: String
    public let options: [AccessibleDropdownOption]
    @Binding public var selected: AccessibleDropdownOption?
    public var configuration: AccessibleDropdownConfiguration = .init()
    public var onSelect: ((AccessibleDropdownOption) -> Void)?

    // MARK: - Init

    public init(
        label: String,
        placeholder: String = "Select an option",
        options: [AccessibleDropdownOption],
        selected: Binding<AccessibleDropdownOption?>,
        configuration: AccessibleDropdownConfiguration = .init(),
        onSelect: ((AccessibleDropdownOption) -> Void)? = nil
    ) {
        self.label         = label
        self.placeholder   = placeholder
        self.options       = options
        self._selected     = selected
        self.configuration = configuration
        self.onSelect      = onSelect
    }

    // MARK: - UIViewRepresentable

    public func makeUIView(context: Context) -> AccessibleDropdown {
        let dropdown           = AccessibleDropdown()
        dropdown.fieldLabel    = label
        dropdown.placeholder   = placeholder
        dropdown.options       = options
        dropdown.configuration = configuration
        dropdown.onSelect      = { option in
            selected = option
            onSelect?(option)
        }
        // Allow the view to shrink/grow with its intrinsicContentSize
        dropdown.setContentHuggingPriority(.required, for: .vertical)
        dropdown.setContentCompressionResistancePriority(.required, for: .vertical)
        return dropdown
    }

    public func updateUIView(_ uiView: AccessibleDropdown, context: Context) {
        uiView.fieldLabel    = label
        uiView.placeholder   = placeholder
        uiView.options       = options
        uiView.configuration = configuration
        // Only push new selection when it actually differs
        if uiView.selectedOption?.id != selected?.id {
            uiView.setSelectedOption(selected)
        }
    }
}
