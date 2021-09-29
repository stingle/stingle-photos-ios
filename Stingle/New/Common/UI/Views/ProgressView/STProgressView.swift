//
//  STProgressView.swift
//  Stingle
//
//  Created by Khoren Asatryan on 8/28/21.
//

import UIKit

class STProgressView: UIView {
    
    @IBOutlet weak private var titleLabel: UILabel!
    @IBOutlet weak private var subTitleLabel: UILabel!
    @IBOutlet weak private var progressView: UIProgressView!
    
    var title: String? {
        set {
            self.titleLabel.text = newValue
        } get {
            return self.titleLabel.text
        }
    }
    
    var subTitle: String? {
        set {
            
            if !Thread.isMainThread {
                print("")
            }
            
            self.subTitleLabel.text = newValue
        } get {
            return self.subTitleLabel.text
        }
    }
    
    var progress: Float {
        set {
            self.progressView.progress = newValue
        } get {
            return self.progressView.progress
        }
    }
    
    
    init() {
        super.init(frame: CGRect.init(origin: .zero, size: CGSize.init(width: 100, height: 200)))
        defer {
            self.backgroundColor = .clear
            self.setup()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func show(in view: UIView) {
        self.alpha = .zero
        view.addSubviewFullContent(view: self)
        UIView.animate(withDuration: 0.3) {
            self.alpha = 1
        }
    }
    
    func hide() {
        UIView.animate(withDuration: 0.3) {
            self.alpha = .zero
        } completion: { [weak self] _ in
            self?.removeFromSuperview()
        }
    }
    
    //MARK: - Private methods
    
    private func setup() {
        let contentView = Bundle.main.loadNibNamed("STProgressView", owner: self, options: nil)?.first as! UIView
        self.addSubviewFullContent(view: contentView)
    }
    
}
