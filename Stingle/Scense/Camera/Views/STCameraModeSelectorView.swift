//
//  STCameraModeSelectorView.swift
//  Stingle
//
//  Horizontal, stock-style mode picker (PHOTO / VIDEO / SLO-MO ...).
//

import UIKit
import StingleRoot

protocol STCameraModeSelectorViewDelegate: AnyObject {
    func modeSelector(_ view: STCameraModeSelectorView, didSelect mode: STCameraMode)
}

final class STCameraModeSelectorView: UIView {

    weak var delegate: STCameraModeSelectorViewDelegate?

    private let scrollView = UIScrollView()
    private let stack = UIStackView()
    private var buttons: [STCameraMode: UIButton] = [:]
    private(set) var modes: [STCameraMode] = []
    private(set) var selectedMode: STCameraMode = .photo

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.commonInit()
    }

    private func commonInit() {
        self.scrollView.showsHorizontalScrollIndicator = false
        self.scrollView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(self.scrollView)

        self.stack.axis = .horizontal
        self.stack.spacing = 22
        self.stack.alignment = .center
        self.stack.translatesAutoresizingMaskIntoConstraints = false
        self.scrollView.addSubview(self.stack)

        NSLayoutConstraint.activate([
            self.scrollView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            self.scrollView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            self.scrollView.topAnchor.constraint(equalTo: self.topAnchor),
            self.scrollView.bottomAnchor.constraint(equalTo: self.bottomAnchor),

            self.stack.topAnchor.constraint(equalTo: self.scrollView.topAnchor),
            self.stack.bottomAnchor.constraint(equalTo: self.scrollView.bottomAnchor),
            self.stack.heightAnchor.constraint(equalTo: self.scrollView.heightAnchor),
            self.stack.leadingAnchor.constraint(equalTo: self.scrollView.leadingAnchor, constant: 0),
            self.stack.trailingAnchor.constraint(equalTo: self.scrollView.trailingAnchor, constant: 0)
        ])
    }

    func configure(modes: [STCameraMode], selected: STCameraMode) {
        self.modes = modes
        self.buttons.removeAll()
        self.stack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        for mode in modes {
            let button = UIButton(type: .system)
            button.setTitle(self.title(for: mode), for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: 13, weight: .semibold)
            button.tag = mode.rawValue
            button.addTarget(self, action: #selector(self.didTapMode(_:)), for: .touchUpInside)
            self.buttons[mode] = button
            self.stack.addArrangedSubview(button)
        }
        self.select(mode: modes.contains(selected) ? selected : (modes.first ?? .photo), notify: false)
        self.setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // Center the buttons when they fit; allow scrolling when they overflow.
        self.layoutIfNeeded()
        let contentWidth = self.scrollView.contentSize.width
        let inset = max(0, (self.bounds.width - contentWidth) / 2)
        if self.scrollView.contentInset.left != inset {
            self.scrollView.contentInset = UIEdgeInsets(top: 0, left: inset, bottom: 0, right: inset)
        }
    }

    func select(mode: STCameraMode, notify: Bool) {
        guard self.modes.contains(mode) else { return }
        self.selectedMode = mode
        for (key, button) in self.buttons {
            let isSelected = key == mode
            button.setTitleColor(isSelected ? .systemYellow : .white, for: .normal)
            button.transform = isSelected ? CGAffineTransform(scaleX: 1.05, y: 1.05) : .identity
        }
        if let button = self.buttons[mode], self.scrollView.contentSize.width > self.bounds.width {
            // Only scroll the selection into view when the buttons overflow.
            self.layoutIfNeeded()
            let rect = button.convert(button.bounds, to: self.scrollView)
            self.scrollView.scrollRectToVisible(rect.insetBy(dx: -60, dy: 0), animated: true)
        }
        if notify { self.delegate?.modeSelector(self, didSelect: mode) }
    }

    @objc private func didTapMode(_ sender: UIButton) {
        guard let mode = STCameraMode(rawValue: sender.tag) else { return }
        self.select(mode: mode, notify: true)
    }

    private func title(for mode: STCameraMode) -> String {
        switch mode {
        case .photo: return "camera_mode_photo".localized
        case .video: return "camera_mode_video".localized
        case .slowmo: return "camera_mode_slowmo".localized
        case .timelapse: return "camera_mode_timelapse".localized
        case .portrait: return "camera_mode_portrait".localized
        }
    }
}
