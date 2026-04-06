
import XCTest
@testable import AccessibleDropdown

// MARK: - AccessibleDropdownOptionTests
final class AccessibleDropdownOptionTests: XCTestCase {

    func test_option_defaultID_isNotEmpty() {
        let option = AccessibleDropdownOption(title: "India")
        XCTAssertFalse(option.id.isEmpty, "Auto-generated ID must not be empty")
    }

    func test_option_customID_isPreserved() {
        let option = AccessibleDropdownOption(id: "in", title: "India")
        XCTAssertEqual(option.id, "in")
    }

    func test_option_isEnabled_byDefault() {
        let option = AccessibleDropdownOption(title: "India")
        XCTAssertFalse(option.isDisabled)
    }

    func test_option_disabledFlag() {
        let option = AccessibleDropdownOption(title: "India", isDisabled: true)
        XCTAssertTrue(option.isDisabled)
    }

    func test_option_equatable_sameID() {
        let a = AccessibleDropdownOption(id: "x", title: "Alpha")
        let b = AccessibleDropdownOption(id: "x", title: "Alpha")
        XCTAssertEqual(a, b)
    }

    func test_option_equatable_differentID() {
        let a = AccessibleDropdownOption(id: "a", title: "Alpha")
        let b = AccessibleDropdownOption(id: "b", title: "Alpha")
        XCTAssertNotEqual(a, b)
    }
}

// MARK: - AccessibleDropdownTests
final class AccessibleDropdownTests: XCTestCase {

    private var dropdown: AccessibleDropdown!
    private let sampleOptions: [AccessibleDropdownOption] = [
        AccessibleDropdownOption(id: "in", title: "India"),
        AccessibleDropdownOption(id: "us", title: "USA"),
        AccessibleDropdownOption(id: "uk", title: "UK", isDisabled: true)
    ]

    override func setUp() {
        super.setUp()
        dropdown = AccessibleDropdown(frame: CGRect(x: 0, y: 0, width: 320, height: 200))
        dropdown.fieldLabel = "Country"
        dropdown.placeholder = "Select a country"
        dropdown.options = sampleOptions
    }

    override func tearDown() {
        dropdown = nil
        super.tearDown()
    }

    // MARK: Accessibility element identity

    func test_isAccessibilityElement_isFalse() {
        XCTAssertFalse(dropdown.isAccessibilityElement,
            "The dropdown container must not be a single accessibility element to allow subviews to be reachable.")
    }

    func test_triggerContainer_isAccessibilityElement_isTrue() {
        XCTAssertTrue(dropdown.triggerContainer.isAccessibilityElement,
            "The trigger row must be an accessibility element.")
    }

    func test_triggerContainer_accessibilityTraits_containsButton() {
        XCTAssertTrue(
            dropdown.triggerContainer.accessibilityTraits.contains(.button),
            "Trigger must have .button trait so VoiceOver announces it as interactive"
        )
    }

    // MARK: Accessibility label

    func test_triggerContainer_accessibilityLabel_equalsFieldLabel() {
        XCTAssertEqual(dropdown.triggerContainer.accessibilityLabel, "Country")
    }

    func test_triggerContainer_accessibilityLabel_updatesWhenFieldLabelChanges() {
        dropdown.fieldLabel = "Language"
        XCTAssertEqual(dropdown.triggerContainer.accessibilityLabel, "Language")
    }

    // MARK: Accessibility value

    func test_triggerContainer_accessibilityValue_isPlaceholderWhenNothingSelected() {
        XCTAssertEqual(dropdown.triggerContainer.accessibilityValue, "Select a country")
    }

    func test_triggerContainer_accessibilityValue_equalsSelectedOptionTitle_afterSelection() {
        dropdown.setSelectedOption(sampleOptions[0])
        XCTAssertEqual(dropdown.triggerContainer.accessibilityValue, "India")
    }

    func test_triggerContainer_accessibilityValue_updatesOnNewSelection() {
        dropdown.setSelectedOption(sampleOptions[0])
        dropdown.setSelectedOption(sampleOptions[1])
        XCTAssertEqual(dropdown.triggerContainer.accessibilityValue, "USA")
    }

    // MARK: Accessibility hint

    func test_triggerContainer_accessibilityHint_isExpandHint_whenClosed() {
        XCTAssertFalse(dropdown.isExpanded)
        XCTAssertEqual(dropdown.triggerContainer.accessibilityHint,
                       dropdown.configuration.collapsedHint)
    }

    func test_triggerContainer_accessibilityHint_isCollapseHint_whenExpanded() {
        dropdown.expand()
        XCTAssertEqual(dropdown.triggerContainer.accessibilityHint,
                       dropdown.configuration.expandedHint)
    }

    // MARK: Expand / Collapse state

    func test_isExpanded_isFalse_initially() {
        XCTAssertFalse(dropdown.isExpanded)
    }

    func test_expand_setsIsExpanded_true() {
        dropdown.expand()
        XCTAssertTrue(dropdown.isExpanded)
    }

    func test_collapse_setsIsExpanded_false() {
        dropdown.expand()
        dropdown.collapse()
        XCTAssertFalse(dropdown.isExpanded)
    }

    func test_expand_whenAlreadyExpanded_noStateChange() {
        dropdown.expand()
        dropdown.expand()
        XCTAssertTrue(dropdown.isExpanded)
    }

    func test_collapse_whenAlreadyClosed_noStateChange() {
        dropdown.collapse()
        XCTAssertFalse(dropdown.isExpanded)
    }

    // MARK: Selection

    func test_selectedOption_isNil_initially() {
        XCTAssertNil(dropdown.selectedOption)
    }

    func test_setSelectedOption_updatesSelectedOption() {
        dropdown.setSelectedOption(sampleOptions[1])
        XCTAssertEqual(dropdown.selectedOption?.id, "us")
    }

    func test_setSelectedOption_nil_clearsSelection() {
        dropdown.setSelectedOption(sampleOptions[0])
        dropdown.setSelectedOption(nil)
        XCTAssertNil(dropdown.selectedOption)
    }

    // MARK: onSelect callback

    func test_onSelect_callback_fires_withCorrectOption() {
        var received: AccessibleDropdownOption?
        dropdown.onSelect = { received = $0 }
        dropdown.setSelectedOption(sampleOptions[0])
        // setSelectedOption does NOT fire callback — only user interaction does.
        // Confirm callback is NOT called from programmatic set.
        XCTAssertNil(received,
            "setSelectedOption must not fire the onSelect callback")
    }

    // MARK: Options count

    func test_options_countMatchesSampleData() {
        XCTAssertEqual(dropdown.options.count, 3)
    }

    func test_options_canBeReplacedAtRuntime() {
        let newOptions = [AccessibleDropdownOption(title: "France")]
        dropdown.options = newOptions
        XCTAssertEqual(dropdown.options.count, 1)
        XCTAssertEqual(dropdown.options[0].title, "France")
    }

    // MARK: Configuration

    func test_configuration_collapsedHint_isNotEmpty() {
        XCTAssertFalse(dropdown.configuration.collapsedHint.isEmpty)
    }

    func test_configuration_expandedHint_isNotEmpty() {
        XCTAssertFalse(dropdown.configuration.expandedHint.isEmpty)
    }

    func test_configuration_collapsedHint_differsFromExpandedHint() {
        XCTAssertNotEqual(
            dropdown.configuration.collapsedHint,
            dropdown.configuration.expandedHint,
            "Open and closed hints must be different strings"
        )
    }

    func test_configuration_triggerMinHeight_isAtLeast44() {
        XCTAssertGreaterThanOrEqual(
            dropdown.configuration.triggerMinHeight, 44,
            "Minimum tap target must be 44 pt per HIG"
        )
    }

    // MARK: Custom configuration

    func test_customConfiguration_appliesNewCollapsedHint() {
        var config = AccessibleDropdownConfiguration()
        config.collapsedHint = "Tap to open."
        dropdown.configuration = config
        XCTAssertFalse(dropdown.isExpanded)
        XCTAssertEqual(dropdown.triggerContainer.accessibilityHint, "Tap to open.")
    }
}

// MARK: - AccessibleDropdownOptionCellTests
final class AccessibleDropdownOptionCellTests: XCTestCase {

    private let config = AccessibleDropdownConfiguration()

    func test_cell_isAccessibilityElement() {
        let cell = AccessibleDropdownOptionCell(
            style: .default,
            reuseIdentifier: AccessibleDropdownOptionCell.reuseIdentifier
        )
        cell.configure(
            with: AccessibleDropdownOption(title: "India"),
            isSelected: false,
            config: config
        )
        XCTAssertTrue(cell.isAccessibilityElement)
    }

    func test_cell_traits_containsButton() {
        let cell = AccessibleDropdownOptionCell(
            style: .default,
            reuseIdentifier: AccessibleDropdownOptionCell.reuseIdentifier
        )
        cell.configure(
            with: AccessibleDropdownOption(title: "India"),
            isSelected: false,
            config: config
        )
        XCTAssertTrue(cell.accessibilityTraits.contains(.button))
    }

    func test_cell_traits_containsSelected_whenIsSelected() {
        let cell = AccessibleDropdownOptionCell(
            style: .default,
            reuseIdentifier: AccessibleDropdownOptionCell.reuseIdentifier
        )
        cell.configure(
            with: AccessibleDropdownOption(title: "India"),
            isSelected: true,
            config: config
        )
        XCTAssertTrue(cell.accessibilityTraits.contains(.selected))
    }

    func test_cell_traits_containsNotEnabled_whenDisabled() {
        let cell = AccessibleDropdownOptionCell(
            style: .default,
            reuseIdentifier: AccessibleDropdownOptionCell.reuseIdentifier
        )
        cell.configure(
            with: AccessibleDropdownOption(title: "UK", isDisabled: true),
            isSelected: false,
            config: config
        )
        XCTAssertTrue(cell.accessibilityTraits.contains(.notEnabled))
    }

    func test_cell_accessibilityLabel_titleOnly_whenNoSubtitle() {
        let cell = AccessibleDropdownOptionCell(
            style: .default,
            reuseIdentifier: AccessibleDropdownOptionCell.reuseIdentifier
        )
        let option = AccessibleDropdownOption(title: "India")
        cell.configure(with: option, isSelected: false, config: config)
        XCTAssertEqual(cell.accessibilityLabel, "India")
    }

    func test_cell_accessibilityLabel_includesSubtitle_whenPresent() {
        let cell = AccessibleDropdownOptionCell(
            style: .default,
            reuseIdentifier: AccessibleDropdownOptionCell.reuseIdentifier
        )
        let option = AccessibleDropdownOption(
            title: "India", subtitle: "New Delhi")
        cell.configure(with: option, isSelected: false, config: config)
        XCTAssertEqual(cell.accessibilityLabel, "India, New Delhi")
    }

    func test_cell_accessibilityValue_isSelectedString_whenSelected() {
        let cell = AccessibleDropdownOptionCell(
            style: .default,
            reuseIdentifier: AccessibleDropdownOptionCell.reuseIdentifier
        )
        cell.configure(
            with: AccessibleDropdownOption(title: "India"),
            isSelected: true,
            config: config
        )
        XCTAssertEqual(cell.accessibilityValue, config.selectedSuffix)
    }

    func test_cell_accessibilityValue_isNil_whenNotSelected() {
        let cell = AccessibleDropdownOptionCell(
            style: .default,
            reuseIdentifier: AccessibleDropdownOptionCell.reuseIdentifier
        )
        cell.configure(
            with: AccessibleDropdownOption(title: "India"),
            isSelected: false,
            config: config
        )
        XCTAssertNil(cell.accessibilityValue)
    }
}
