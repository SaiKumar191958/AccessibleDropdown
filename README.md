# AccessibleDropdown

A fully accessible dropdown / combo-box component for iOS, built with UIKit and SwiftUI support.

## Accessibility features

| Feature | Implementation |
|---|---|
| VoiceOver role | `.button` trait on the trigger |
| VoiceOver label | Your `fieldLabel` string |
| VoiceOver value | Currently selected option title (or placeholder) |
| VoiceOver hint | Changes: expand hint / collapse hint |
| Focus management | Menu open → focus moves to first option via `layoutChanged` notification |
| Focus return | Menu close → focus returns to trigger |
| Announcements | "Menu expanded." / "Menu collapsed." via `.announcement` notification |
| Dynamic Type | All labels use `preferredFont(forTextStyle:)` + `adjustsFontForContentSizeCategory` |
| Minimum tap target | Trigger enforced at ≥ 44 × 44 pt |
| Disabled options | `.notEnabled` trait, non-interactive |
| Selected state | `.selected` trait + `accessibilityValue = "selected"` |

## Requirements

- iOS 14.0+
- Swift 5.9+
- Xcode 15+

## Installation

### Swift Package Manager

In Xcode: **File → Add Package Dependencies**

```
https://github.com/YOUR_USERNAME/AccessibleDropdown
```

Or in `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/YOUR_USERNAME/AccessibleDropdown", from: "1.0.0")
]
```

## Usage — UIKit

```swift
import AccessibleDropdown

let dropdown = AccessibleDropdown()
dropdown.fieldLabel = "Country"
dropdown.placeholder = "Select a country"
dropdown.options = [
    AccessibleDropdownOption(title: "India"),
    AccessibleDropdownOption(title: "USA"),
    AccessibleDropdownOption(title: "UK", isDisabled: true)
]
dropdown.onSelect = { option in
    print("Selected:", option.title)
}
view.addSubview(dropdown)
```

## Usage — SwiftUI

```swift
import AccessibleDropdown
import SwiftUI

struct ContentView: View {
    @State private var selected: AccessibleDropdownOption?

    let countries = [
        AccessibleDropdownOption(title: "India"),
        AccessibleDropdownOption(title: "USA"),
        AccessibleDropdownOption(title: "UK")
    ]

    var body: some View {
        AccessibleDropdownView(
            label: "Country",
            placeholder: "Select a country",
            options: countries,
            selected: $selected
        )
        .frame(height: 80)
        .padding()
    }
}
```

## Customisation

```swift
var config = AccessibleDropdownConfiguration()
config.triggerMinHeight   = 50
config.optionRowHeight    = 52
config.cornerRadius       = 12
config.collapsedHint      = "Double tap to open country list."
config.expandedHint       = "Double tap to close country list."
config.menuOpenedAnnouncement = "Country list expanded."
config.menuClosedAnnouncement = "Country list collapsed."

dropdown.configuration = config
```

## Running Tests

```bash
cd AccessibleDropdown
swift test
```

## Part of AccessibleUI

This package is part of the **AccessibleUI** suite of 12 accessible iOS components:

- **AccessibleDropdown** ← you are here
- AccessiblePicker
- AccessibleTextField
- AccessibleCheckbox
- AccessibleButton
- AccessibleToggle
- AccessibleSlider
- AccessibleRating
- AccessibleTabBar
- AccessibleList
- AccessibleModal
- AccessibleToast

## License

MIT
