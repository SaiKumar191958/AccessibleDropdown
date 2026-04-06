//
//  File.swift
//  AccessibleDropdown
//
//  Created by Sai Babu on 06/04/26.
//
import UIKit

// MARK: - AccessibleDropdownMenuView
/// Works in both overlay (floating in UIWindow) and inline (subview) modes.
/// The caller decides placement; this view just displays options.
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

    var onSelect:  ((AccessibleDropdownOption) -> Void)?
    var onDismiss: (() -> Void)?

    /// Returns the ideal height for the given configuration.
    /// Callers use this to size the menu before displaying it.
    func preferredHeight(config: AccessibleDropdownConfiguration) -> CGFloat {
        let rows = min(options.count, config.theme.maxVisibleRows)
        return CGFloat(rows) * config.theme.optionRowHeight
    }

    // MARK: - Subviews

    /// Clip container so table cells stay within the rounded border.
    private let clipContainer: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.clipsToBounds = true
        return v
    }()

    private let tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.separatorInset        = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        tv.showsVerticalScrollIndicator = true
        tv.backgroundColor       = .clear
        tv.isAccessibilityElement = false
        return tv
    }()

    // Transparent full-screen view behind the menu (overlay mode only)
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
        isAccessibilityElement      = false
        accessibilityElementsHidden = false

        // Shadow is on self (masksToBounds = false)
        // Rounded clipping is on clipContainer
        clipsToBounds = false

        addSubview(clipContainer)
        NSLayoutConstraint.activate([
            clipContainer.topAnchor.constraint(equalTo: topAnchor),
            clipContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            clipContainer.trailingAnchor.constraint(equalTo: trailingAnchor),
            clipContainer.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        tableView.register(
            AccessibleDropdownOptionCell.self,
            forCellReuseIdentifier: AccessibleDropdownOptionCell.reuseIdentifier
        )
        tableView.dataSource = self
        tableView.delegate   = self

        clipContainer.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: clipContainer.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: clipContainer.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: clipContainer.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: clipContainer.bottomAnchor)
        ])

        applyStyle()
    }

    // MARK: - Styling

    private func applyStyle() {
        let t = configuration.theme
        let isOverlay = configuration.expansionStyle == .overlay

        // Card appearance
        clipContainer.backgroundColor       = t.menuBackground
        clipContainer.layer.cornerRadius    = t.cornerRadius
        clipContainer.layer.borderWidth     = t.borderWidth
        clipContainer.layer.borderColor     = t.triggerBorder.cgColor

        tableView.separatorColor            = t.separator
        tableView.rowHeight                 = t.optionRowHeight
        tableView.backgroundColor           = t.menuBackground

        // Shadow — only in overlay mode if enabled
        if isOverlay && configuration.showMenuShadow {
            layer.shadowColor   = configuration.menuShadowColor.cgColor
            layer.shadowOpacity = 1
            layer.shadowRadius  = configuration.menuShadowRadius
            layer.shadowOffset  = CGSize(width: 0, height: 3)
        } else {
            layer.shadowOpacity = 0
        }

        tableView.isScrollEnabled = options.count > t.maxVisibleRows
    }

    // MARK: - Window lifecycle (overlay mode: install dismiss overlay)

    override func didMoveToWindow() {
        super.didMoveToWindow()
        if let window = window,
           configuration.expansionStyle == .overlay {
            installDismissOverlay(in: window)
        } else {
            dismissOverlay?.removeFromSuperview()
        }
    }

    private func installDismissOverlay(in window: UIWindow) {
        // Remove any stale overlay first
        dismissOverlay?.removeFromSuperview()

        let overlay = UIView(frame: window.bounds)
        overlay.autoresizingMask  = [.flexibleWidth, .flexibleHeight]
        overlay.backgroundColor   = .clear
        overlay.isAccessibilityElement = false
        let tap = UITapGestureRecognizer(target: self,
                                         action: #selector(overlayTapped))
        overlay.addGestureRecognizer(tap)
        window.insertSubview(overlay, belowSubview: self)
        dismissOverlay = overlay
    }

    @objc private func overlayTapped() { onDismiss?() }

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

    func tableView(_ tv: UITableView,
                   numberOfRowsInSection section: Int) -> Int { options.count }

    func tableView(_ tv: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tv.dequeueReusableCell(
            withIdentifier: AccessibleDropdownOptionCell.reuseIdentifier,
            for: indexPath) as? AccessibleDropdownOptionCell
        else { return UITableViewCell() }

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
        configuration.theme.optionRowHeight
    }
}
