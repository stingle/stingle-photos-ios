//
//  UINavigationBar+Progress.swift
//  Stingle
//
//  Created by Khoren Asatryan on 5/15/21.
//

import UIKit

extension UINavigationBar {
    
    private static let progressViewTag = 20001
    
    //MARK: - Public
    
    func setProgress(progress: Float) {
        self.progressView.progress = progress
    }
    
    func setProgressView(isHidden: Bool) {
        self.progressView.isHidden = isHidden
    }
    
    //MARK: - Private
    
    private var progressView: UIProgressView {
        for subview in self.subviews {
            if subview.tag == Self.progressViewTag, let progressView = subview as? UIProgressView {
                return progressView
            }
        }
        return self.createProgressView()
    }
    
    private func createProgressView() -> UIProgressView {
        var frame = self.bounds
        let height: CGFloat = 5
        frame.origin.y = frame.height - height
        frame.size.height = height
        let progressView = UIProgressView(frame: frame)
        progressView.tag = Self.progressViewTag
        progressView.autoresizingMask = [.flexibleWidth, .flexibleTopMargin]
        self.addSubview(progressView)
        progressView.progressTintColor = .appPrimary
        return progressView
    }
    
}

