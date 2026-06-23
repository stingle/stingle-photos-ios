//
//  STCameraLensSelectorView.swift
//  Stingle
//
//  Stock-style preset zoom/lens buttons (0.5×, 1×, 2×, 3×…) derived from the
//  device's actual lenses.
//

import UIKit
import StingleRoot

protocol STCameraLensSelectorViewDelegate: AnyObject {
    func lensSelector(_ view: STCameraLensSelectorView, didSelect lens: STLens)
}

final class STCameraLensSelectorView: UIView {

    weak var delegate: STCameraLensSelectorViewDelegate?

    private let stack = UIStackView()
    private var buttons: [UIButton] = []
    private(set) var lenses: [STLens] = []
    private var selectedIndex: Int = 0

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.commonInit()
    }

    private func commonInit() {
        self.stack.axis = .horizontal
        self.stack.spacing = 8
        self.stack.alignment = .center
        self.stack.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(self.stack)
        // Pin the stack to the view's edges (with padding) so the view derives a
        // real width from its buttons — otherwise it collapses to zero width and
        // taps fall through to the preview's focus gesture.
        NSLayoutConstraint.activate([
            self.stack.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 10),
            self.stack.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -10),
            self.stack.centerYAnchor.constraint(equalTo: self.centerYAnchor)
        ])
        // Pill background behind the buttons.
        self.backgroundColor = UIColor.black.withAlphaComponent(0.35)
        self.layer.cornerRadius = 18
    }

    func configure(lenses: [STLens]) {
        self.lenses = lenses
        self.buttons.forEach { $0.removeFromSuperview() }
        self.buttons.removeAll()
        self.stack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        // A single lens needs no picker.
        self.isHidden = lenses.count < 2

        for (index, lens) in lenses.enumerated() {
            let button = UIButton(type: .custom)
            button.tag = index
            button.titleLabel?.font = .systemFont(ofSize: 13, weight: .semibold)
            button.addTarget(self, action: #selector(self.didTap(_:)), for: .touchUpInside)
            button.widthAnchor.constraint(greaterThanOrEqualToConstant: 34).isActive = true
            button.heightAnchor.constraint(equalToConstant: 34).isActive = true
            button.layer.cornerRadius = 17
            button.setTitle(self.title(for: lens, selected: false), for: .normal)
            self.buttons.append(button)
            self.stack.addArrangedSubview(button)
        }
        self.setSelected(index: self.nearestIndex(toDisplay: 1))
    }

    /// Highlights the lens nearest the live zoom (used during pinch).
    func updateSelection(forDisplayZoom display: CGFloat) {
        self.setSelected(index: self.nearestIndex(toDisplay: display), display: display)
    }

    private func nearestIndex(toDisplay display: CGFloat) -> Int {
        guard !self.lenses.isEmpty else { return 0 }
        var best = 0
        var bestDelta = CGFloat.greatestFiniteMagnitude
        for (index, lens) in self.lenses.enumerated() {
            let delta = abs(lens.displayZoom - display)
            if delta < bestDelta { bestDelta = delta; best = index }
        }
        return best
    }

    private func setSelected(index: Int, display: CGFloat? = nil) {
        self.selectedIndex = index
        for (i, button) in self.buttons.enumerated() {
            let lens = self.lenses[i]
            let isSelected = i == index
            button.backgroundColor = isSelected ? UIColor.black.withAlphaComponent(0.5) : .clear
            button.setTitleColor(isSelected ? .systemYellow : .white, for: .normal)
            // The selected button shows the live multiplier (e.g. "1.4×"); others
            // show their nominal stop (e.g. ".5", "2").
            if isSelected, let display {
                button.setTitle(String(format: "%.1f×", display), for: .normal)
            } else {
                button.setTitle(self.title(for: lens, selected: isSelected), for: .normal)
            }
        }
    }

    private func title(for lens: STLens, selected: Bool) -> String {
        // Stock-style: sub-1× shown as ".5", whole numbers as "1", "2".
        if lens.displayZoom < 1 {
            return String(format: "%.1f", lens.displayZoom).replacingOccurrences(of: "0.", with: ".")
        }
        if lens.displayZoom == lens.displayZoom.rounded() {
            return "\(Int(lens.displayZoom))" + (selected ? "×" : "")
        }
        return String(format: "%.1f", lens.displayZoom)
    }

    @objc private func didTap(_ sender: UIButton) {
        let index = sender.tag
        guard index < self.lenses.count else { return }
        self.setSelected(index: index)
        self.delegate?.lensSelector(self, didSelect: self.lenses[index])
    }
}
