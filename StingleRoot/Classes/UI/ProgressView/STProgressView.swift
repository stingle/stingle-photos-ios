//
//  STProgressView.swift
//  Stingle
//
//  Created by Khoren Asatryan on 8/28/21.
//

import UIKit

public class STProgressView: UIView {
    
    @IBOutlet weak private var titleLabel: UILabel!
    @IBOutlet weak private var subTitleLabel: UILabel!
    @IBOutlet weak private var progressView: UIProgressView!
    
    public var title: String? {
        set {
            self.titleLabel.text = newValue
        } get {
            return self.titleLabel.text
        }
    }
    
    public var subTitle: String? {
        set {
            self.subTitleLabel.text = newValue
        } get {
            return self.subTitleLabel.text
        }
    }
    
    public var progress: Float {
        set {
            self.progressView.progress = newValue
        } get {
            return self.progressView.progress
        }
    }
    
    public init() {
        super.init(frame: CGRect.init(origin: .zero, size: CGSize.init(width: 100, height: 200)))
        defer {
            self.backgroundColor = .clear
            self.setup()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func show(in view: UIView) {
        self.alpha = .zero
        self.frame = view.bounds
        self.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(self)
        UIView.animate(withDuration: 0.3) {
            self.alpha = 1
        }
    }
    
    public func hide() {
        UIView.animate(withDuration: 0.3) {
            self.alpha = .zero
        } completion: { [weak self] _ in
            self?.removeFromSuperview()
        }
    }
    
    //MARK: - Private methods
    
    private func setup() {
        let bundle = Bundle(for: type(of: self))
        let contentView = bundle.loadNibNamed("STProgressView", owner: self, options: nil)?.first as! UIView
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.addSubview(contentView)
    }
    
}
