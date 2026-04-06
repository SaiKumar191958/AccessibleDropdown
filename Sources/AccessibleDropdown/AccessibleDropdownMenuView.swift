//
//  File.swift
//  AccessibleDropdown
//
//  Created by Sai Babu on 06/04/26.
//

import UIKit

// MARK: - AccessibleDropdownMenuView
/// The card that appears below the trigger button listing all options.
///
/// Accessibility:
/// - The container view itself is NOT an accessibility element
///   (isAccessibilityElement = false).
/// - Each cell is its own accessibility element so VoiceOver users
///   can swipe through options individually.
/// - A UIAccessibilityLayoutChangedNotification is posted with focus
///   moved to the first enabled option when the menu opens.
///
final class AccessibleDropdownMenuView: UIView {

    // MARK: Properties

    var options: [AccessibleDropdownOption] = [] {
        didSet { tableView.reloadData() }
    }

    var selectedOption: AccessibleDropdownOption? {
        didSet { tableView.reloadData() }
    }

    var configuration: AccessibleDropdownConfiguration = .init() {
        didSet { applyConfiguration() }
    }

    /// Called when the user taps a non-disabled option.
    var onSelect: ((AccessibleDropdownOption) -> Void)?

    // MARK: Subviews

    private let tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        tv.showsVerticalScrollIndicator = false
        tv.backgroundColor = .clear
        // The table is NOT an accessibility container — cells are.
        tv.isAccessibilityElement = false
        return tv
    }()

    private var heightConstraint: NSLayoutConstraint!

    // MARK: Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    // MARK: Setup

    private func setup() {
        layer.masksToBounds = true
        layer.cornerRadius = 10
        layer.borderWidth = 0.5

        // This container is purely structural — VoiceOver must walk
        // into the cells, not announce the container itself.
        isAccessibilityElement = false
        accessibilityElementsHidden = false

        tableView.register(
            AccessibleDropdownOptionCell.self,
            forCellReuseIdentifier: AccessibleDropdownOptionCell.reuseIdentifier
        )
        tableView.dataSource = self
        tableView.delegate = self

        addSubview(tableView)
        heightConstraint = tableView.heightAnchor.constraint(equalToConstant: 0)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: topAnchor),
            tableView.leadingAnchor.constraint(equalTo: leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: bottomAnchor),
            heightConstraint
        ])
    }

    private func applyConfiguration() {
        backgroundColor = configuration.menuBackgroundColor
        layer.borderColor = configuration.triggerBorderColor.cgColor
        layer.cornerRadius = configuration.cornerRadius
        tableView.separatorColor = configuration.separatorColor
        tableView.rowHeight = configuration.optionRowHeight
        recalculateHeight()
    }

    // MARK: Height

    func recalculateHeight() {
        let rowH = configuration.optionRowHeight
        let maxVisible = configuration.maxVisibleRows
        let count = options.count
        let visibleRows = min(count, maxVisible)
        heightConstraint.constant = CGFloat(visibleRows) * rowH
        tableView.isScrollEnabled = count > maxVisible
    }

    // MARK: Focus Management

    /// After the menu opens, move VoiceOver focus to the first enabled cell.
    /// Posts UIAccessibilityLayoutChangedNotification with that cell as target.
    func moveFocusToFirstOption() {
        guard !options.isEmpty else { return }
        let targetIndex = options.firstIndex(where: { !$0.isDisabled }) ?? 0
        let indexPath = IndexPath(row: targetIndex, section: 0)

        // Small delay ensures the cell is visible after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
            guard let cell = self?.tableView.cellForRow(at: indexPath) else { return }
            UIAccessibility.post(
                notification: .layoutChanged,
                argument: cell
            )
        }
    }
}

// MARK: - UITableViewDataSource

extension AccessibleDropdownMenuView: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        options.count
    }

    func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: AccessibleDropdownOptionCell.reuseIdentifier,
            for: indexPath
        ) as? AccessibleDropdownOptionCell else {
            return UITableViewCell()
        }

        let option = options[indexPath.row]
        let isSelected = option.id == selectedOption?.id
        cell.configure(with: option, isSelected: isSelected, config: configuration)
        cell.backgroundColor = configuration.menuBackgroundColor
        return cell
    }
}

// MARK: - UITableViewDelegate

extension AccessibleDropdownMenuView: UITableViewDelegate {

    func tableView(
        _ tableView: UITableView,
        didSelectRowAt indexPath: IndexPath
    ) {
        tableView.deselectRow(at: indexPath, animated: true)
        let option = options[indexPath.row]
        guard !option.isDisabled else { return }
        onSelect?(option)
    }

    func tableView(
        _ tableView: UITableView,
        heightForRowAt indexPath: IndexPath
    ) -> CGFloat {
        configuration.optionRowHeight
    }
}
