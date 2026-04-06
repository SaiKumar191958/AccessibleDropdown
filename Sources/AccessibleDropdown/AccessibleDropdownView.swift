//
//  File.swift
//  AccessibleDropdown
//
//  Created by Sai Babu on 06/04/26.
//
import SwiftUI

// MARK: - AccessibleDropdownView
///
/// SwiftUI wrapper — supports overlay and inline expansion + full theming.
///
/// ── Overlay (default) ────────────────────────────────────────────────
/// The menu floats above sibling views. The dropdown's frame stays
/// constant whether the menu is open or closed.
///
///   AccessibleDropdownView(
///       label: "Country",
///       options: countries,
///       selected: $selected
///   )
///   // No .frame() needed.
///
/// ── Inline ───────────────────────────────────────────────────────────
/// The menu expands inside the layout, pushing siblings down.
///
///   AccessibleDropdownView(
///       label: "Country",
///       options: countries,
///       selected: $selected,
///       configuration: .style(.inline)
///   )
///
/// ── Custom theme ─────────────────────────────────────────────────────
///
///   let myTheme = AccessibleDropdownTheme(
///       triggerBackground : UIColor(named: "Surface")!,
///       triggerBorder     : UIColor(named: "Purple")!,
///       optionSelectedBg  : UIColor(named: "Purple")!.withAlphaComponent(0.15),
///       optionSelectedText: UIColor(named: "Purple")!,
///       chevron           : UIColor(named: "Purple")!,
///       triggerFont       : UIFont(name: "AvenirNext-Medium", size: 16)!,
///       cornerRadius      : 12,
///       triggerHeight     : 50
///   )
///
///   AccessibleDropdownView(
///       label: "Country",
///       options: countries,
///       selected: $selected,
///       configuration: .themed(myTheme, expansionStyle: .overlay)
///   )
///
@available(iOS 14.0, *)
public struct AccessibleDropdownView: UIViewRepresentable {

    // MARK: - Properties

    public let label:         String
    public let placeholder:   String
    public let options:       [AccessibleDropdownOption]
    @Binding public var selected: AccessibleDropdownOption?
    public var configuration: AccessibleDropdownConfiguration = .init()
    public var onSelect:      ((AccessibleDropdownOption) -> Void)?

    // MARK: - Init

    public init(
        label:         String,
        placeholder:   String = "Select an option",
        options:       [AccessibleDropdownOption],
        selected:      Binding<AccessibleDropdownOption?>,
        configuration: AccessibleDropdownConfiguration = .init(),
        onSelect:      ((AccessibleDropdownOption) -> Void)? = nil
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
        dropdown.setContentHuggingPriority(.required, for: .vertical)
        dropdown.setContentCompressionResistancePriority(.required, for: .vertical)
        return dropdown
    }

    public func updateUIView(_ uiView: AccessibleDropdown, context: Context) {
        uiView.fieldLabel    = label
        uiView.placeholder   = placeholder
        uiView.options       = options
        uiView.configuration = configuration
        if uiView.selectedOption?.id != selected?.id {
            uiView.setSelectedOption(selected)
        }
    }
}
