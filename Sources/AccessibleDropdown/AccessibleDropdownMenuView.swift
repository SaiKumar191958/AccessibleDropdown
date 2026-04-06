//
//  File.swift
//  AccessibleDropdown
//
//  Created by Sai Babu on 06/04/26.
//
import UIKit

// MARK: - AccessibleDropdownMenuView
///
/// The floating option list.
///
/// Lives in the UIWindow (not inside AccessibleDropdown's view hierarchy)
/// so its presence / absence never disturbs SwiftUI layout.
///
/// Self-sizes via preferredHeight, then the caller sets .frame directly.
///
final class AccessibleDropdownMenuView: UIView {

    // MARK: - Properties

    var options: [AccessibleDropdownOption] = [] {
        didSet { tableView.reloadData() }
    }

    var selectedOption: AccessibleDropdownOption? {
        didSet { tableView.reloadData() }
    }

    var configuration: AccessibleDropdownConfiguration = .init() {
        didSet { applyStyle() }
    }

    /// Called when the user picks an option.
    var onSelect: ((AccessibleDropdownOption) -> Void)?

    /// Called when the user taps outside the menu (dismiss tap).
    var onDismiss: (() -> Void)?

    /// The ideal height for the menu given the current options + config.
    /// The caller may cap this to the available screen space.
    var preferredHeight: CGFloat {
        let rowH = configuration.optionRowHeight
        let rows = min(options.count, configuration.maxVisibleRows)
        return CGFloat(rows) * rowH
    }

    // MARK: - Subviews

    private let tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        tv.showsVerticalScrollIndicator = true
        tv.backgroundColor = .clear
        tv.isAccessibilityElement = false   // cells are the a11y elements
        return tv
    }()

    /// A full-screen transparent view placed behind the menu to catch
    /// taps-outside and dismiss the menu.
    private weak var dismissOverlay: UIView?

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    // MARK: - Setup

    private func setup() {
        // The menu card itself is NOT an a11y element — cells are.
        isAccessibilityElement     = false
        accessibilityElementsHidden = false

        layer.cornerRadius  = 10
        layer.borderWidth   = 0.5
        layer.masksToBounds = true

        // Drop shadow (applied to layer, not via masksToBounds)
        layer.masksToBounds = false
        layer.shadowColor   = UIColor.black.cgColor
        layer.shadowOpacity = 0.12
        layer.shadowRadius  = 8
        layer.shadowOffset  = CGSize(width: 0, height: 4)

        // Clip subviews (tableView) to the rounded rect
        let clipView = UIView(frame: bounds)
        clipView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        clipView.layer.cornerRadius  = 10
        clipView.layer.masksToBounds = true
        clipView.backgroundColor    = .clear
        addSubview(clipView)

        tableView.register(
            AccessibleDropdownOptionCell.self,
            forCellReuseIdentifier: AccessibleDropdownOptionCell.reuseIdentifier
        )
        tableView.dataSource = self
        tableView.delegate   = self
        clipView.addSubview(tableView)

        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: clipView.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: clipView.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: clipView.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: clipView.bottomAnchor)
        ])

        applyStyle()
    }

    // MARK: - Called by AccessibleDropdown.expand()

    /// Position the menu and install the dismiss overlay behind it.
    func configure(frameInWindow frame: CGRect) {
        self.frame = frame
        tableView.isScrollEnabled = options.count > configuration.maxVisibleRows
    }

    // MARK: - Window lifecycle

    override func didMoveToWindow() {
        super.didMoveToWindow()
        if let window = window {
            installDismissOverlay(in: window)
        } else {
            dismissOverlay?.removeFromSuperview()
        }
    }

    private func installDismissOverlay(in window: UIWindow) {
        let overlay = UIView(frame: window.bounds)
        overlay.autoresizingMask  = [.flexibleWidth, .flexibleHeight]
        overlay.backgroundColor   = .clear
        overlay.isAccessibilityElement = false
        let tap = UITapGestureRecognizer(
            target: self, action: #selector(overlayTapped))
        overlay.addGestureRecognizer(tap)
        // Insert behind the menu card
        window.insertSubview(overlay, belowSubview: self)
        dismissOverlay = overlay
    }

    @objc private func overlayTapped() {
        onDismiss?()
    }

    // MARK: - Styling

    private func applyStyle() {
        backgroundColor             = configuration.menuBackgroundColor
        layer.borderColor           = configuration.triggerBorderColor.cgColor
        layer.cornerRadius          = configuration.cornerRadius
        tableView.separatorColor    = configuration.separatorColor
        tableView.rowHeight         = configuration.optionRowHeight
        tableView.backgroundColor   = configuration.menuBackgroundColor
    }

    // MARK: - Accessibility focus

    func moveFocusToFirstOption() {
        guard !options.isEmpty else { return }
        let idx = options.firstIndex(where: { !$0.isDisabled }) ?? 0
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
            guard let cell = self?.tableView.cellForRow(
                at: IndexPath(row: idx, section: 0)) else { return }
            UIAccessibility.post(notification: .layoutChanged, argument: cell)
        }
    }
}

// MARK: - UITableViewDataSource

extension AccessibleDropdownMenuView: UITableViewDataSource {

    func tableView(_ tv: UITableView, numberOfRowsInSection section: Int) -> Int {
        options.count
    }

    func tableView(_ tv: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tv.dequeueReusableCell(
            withIdentifier: AccessibleDropdownOptionCell.reuseIdentifier,
            for: indexPath) as? AccessibleDropdownOptionCell else {
            return UITableViewCell()
        }
        let option     = options[indexPath.row]
        let isSelected = option.id == selectedOption?.id
        cell.configure(with: option, isSelected: isSelected, config: configuration)
        return cell
    }
}

// MARK: - UITableViewDelegate

extension AccessibleDropdownMenuView: UITableViewDelegate {

    func tableView(_ tv: UITableView, didSelectRowAt indexPath: IndexPath) {
        tv.deselectRow(at: indexPath, animated: true)
        let option = options[indexPath.row]
        guard !option.isDisabled else { return }
        onSelect?(option)
    }

    func tableView(_ tv: UITableView,
                   heightForRowAt indexPath: IndexPath) -> CGFloat {
        configuration.optionRowHeight
    }
}
