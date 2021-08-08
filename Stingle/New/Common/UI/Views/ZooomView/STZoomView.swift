//
//  STZoomView.swift
//  Stingle
//
//  Created by Khoren Asatryan on 6/23/21.
//

import UIKit

protocol IZoomContentView: UIView {
    
    var contentSize: CGSize { get }
    
}

protocol STZoomViewDelegate: AnyObject {
    
    func zoomViewDidZoom(_ zoomView: STZoomView)
    
}

class STZoomView: UIView, UIGestureRecognizerDelegate {
 
    private var isSetupScrollZoomView = false
    private var scrollView: UIScrollView!
    private var oldContentViewSize: CGSize?
    private var isReloadindZoom = false
    
    weak var delegate: STZoomViewDelegate?
    
    let maximumZoomScale: CGFloat = 5
    let minimumZoomScale: CGFloat = 1
    
    var contentView: IZoomContentView? {
        didSet {
            self.reloatContentView()
        }
    }
    
    private var contentViewFrame: CGRect {
        get {
            guard let contentView = self.contentView else {
                return .zero
            }
            return self.convert(contentView.frame, from: contentView.superview)
        }
    }
    
    private var contentViewSize: CGSize? {
                
        guard let contentView = contentView else {
            return nil
        }
        
        var contentSize = contentView.contentSize
        
        if contentSize.width.isNaN || contentSize.height.isNaN {
            contentSize = .zero
        }
        
        let mySize = self.scrollView.bounds.size
        let widthScale = mySize.width / contentSize.width
        let heightScale = mySize.height / contentSize.height
        var scale = min(widthScale, heightScale);
        if !scale.isNormal {
            contentSize = self.scrollView.bounds.size
            scale = 0
        }
        contentSize.width = contentSize.width * scale
        contentSize.height = contentSize.height * scale
        
        defer {
            DispatchQueue.main.async {
                self.oldContentViewSize = contentSize
            }
        }
        
        return contentSize
    }
    
    private var contentViewSetupFrame: CGRect {
        get {
            guard let contentView = self.contentView else {
                return bounds
            }
            let contentViewSize = CGSize(width: contentView.bounds.size.width * minimumZoomScale, height: contentView.bounds.size.height * self.scrollView.minimumZoomScale)
            
            let contentViewOregin = CGPoint(x: (self.scrollView.bounds.size.width - contentViewSize.width) / 2, y: (self.scrollView.bounds.size.height - contentViewSize.height) / 2)
            
            return CGRect(origin: contentViewOregin, size: contentViewSize)
        }
    }
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.configure()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.configure()
    }
    
    //MARK: - UIScrollView
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.reloatItemWithZoom()
    }
    
    //MARK: - Public methods
    
    func zoomContent(didChange zoomContentView: IZoomContentView) {
        
        guard let old = self.oldContentViewSize, let new = self.contentViewSize else {
            return
        }
        
        var oldR = old.height != .zero ? old.width / old.height : .zero
        var newR = new.height != .zero ? new.width / new.height : .zero
        
        oldR = round(oldR * 10) / 10.0
        newR = round(newR * 10) / 10.0
        
        if oldR != newR {
            self.resetScrollSizes()
        }

    }
    
    // MARK: - private

    private func configure() {
        self.addScrollView()
        self.setupTapGesture()
    }
    
    private func addScrollView() {
        self.scrollView = UIScrollView(frame: self.bounds)
        self.scrollView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.scrollView.showsVerticalScrollIndicator = false
        self.scrollView.showsHorizontalScrollIndicator = false
        self.scrollView.decelerationRate = UIScrollView.DecelerationRate(rawValue: 0.2)
        self.scrollView.delegate = self
        self.addSubview(self.scrollView)
        
        self.scrollView.backgroundColor = UIColor.clear
        
        self.scrollView.minimumZoomScale = self.minimumZoomScale
        self.scrollView.maximumZoomScale = self.maximumZoomScale
        self.scrollView.zoomScale = self.scrollView.minimumZoomScale
        self.scrollView.contentInsetAdjustmentBehavior = .never
    }
    
    private func setupTapGesture()  {
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(doubleTap(gesture:)))
        doubleTap.numberOfTapsRequired = 2
        self.addGestureRecognizer(doubleTap)
    }
    
    private func zoomToPoint(zoomPoint: CGPoint, scale: CGFloat, animated: Bool)  {
        guard let contentView = self.contentView else {
            return
        }
        let rect = self.contentViewSetupFrame
        let point = contentView.convert(zoomPoint, from: self)
        var zoomSize = rect.size
        zoomSize = CGSize(width: zoomSize.width / scale, height: zoomSize.height / scale)
        let zoomOregin = CGPoint(x: point.x - zoomSize.width / 2, y: point.y - zoomSize.height / 2)
        let zoomRect = CGRect(origin: zoomOregin, size: zoomSize)
        self.scrollView.zoom(to: zoomRect, animated: animated)
    }
    
    // MARK: - User action
    
    @objc private func doubleTap(gesture: UITapGestureRecognizer)  {
        if  gesture.numberOfTapsRequired != 2 {
            return
        }
        let point = gesture.location(in: self)
        if !self.contentViewFrame.contains(point) {
            return
        }
        
        let zoomFactor = self.scrollView.zoomScale / (self.scrollView.maximumZoomScale != .zero ? self.scrollView.maximumZoomScale : 100)
        
        if zoomFactor > 0.8 {
            self.scrollView.setZoomScale(self.scrollView.minimumZoomScale, animated: true)
        }else {
            self.zoomToPoint(zoomPoint: point, scale: self.scrollView.maximumZoomScale, animated: true)
        }
    }
    
    // MARK: - Private methods
        
    private func reloatContentView() {
        self.scrollView.subviews.forEach( { $0.removeFromSuperview()} )
        guard let contentView = self.contentView else {
            return
        }
        self.scrollView.addSubview(contentView)
        self.resetScrollSizes()
        self.isSetupScrollZoomView = true
    }
    
    private func resetScrollSizes() {
        self.scrollView.zoomScale = self.scrollView.minimumZoomScale
        guard let contentView = self.contentView, let contentViewSize = self.contentViewSize  else {
            return
        }
        contentView.frame = CGRect(x: 0, y: 0, width: contentViewSize.width, height: contentViewSize.height)
        self.scrollView.zoomScale = self.scrollView.minimumZoomScale
        self.reloadContentInset()
    }
        
    private func reloadContentInset()  {
        guard let contentView = self.contentView else {
            return
        }
        let contentViewSize = contentView.frame.size
        let scrollViewSize = self.scrollView.frame.size
        let verticalPadding = contentViewSize.height < scrollViewSize.height ? (scrollViewSize.height - contentViewSize.height) / 2 : 0
        let horizontalPadding = contentViewSize.width < scrollViewSize.width ? (scrollViewSize.width - contentViewSize.width) / 2 : 0
        self.scrollView.contentInset = UIEdgeInsets(top: verticalPadding, left: horizontalPadding, bottom: verticalPadding, right: horizontalPadding)
    }
    
    private func reloatItemWithZoom() {
        guard let contentView = self.contentView, self.isSetupScrollZoomView, !self.scrollView.zoomScale.isNaN, contentView.center != .zero, let contentViewSize = self.contentViewSize else {
            return
        }
        
        self.isReloadindZoom = true
        
        let currentViewFrame = contentView.frame
        let currentViewSize = CGSize(width: currentViewFrame.width / self.scrollView.zoomScale * self.scrollView.minimumZoomScale, height: currentViewFrame.height / self.scrollView.zoomScale * self.scrollView.minimumZoomScale)
        
        if currentViewSize != contentViewSize {
            let scale = contentViewSize.height / currentViewSize.height
            let newZoom = self.scrollView.zoomScale * scale
           
            if newZoom > self.scrollView.zoomScale {
                self.scrollView.zoomScale = newZoom
                self.scrollView.minimumZoomScale = scale * self.scrollView.minimumZoomScale
                self.scrollView.maximumZoomScale = self.maximumZoomScale * scale * self.scrollView.minimumZoomScale
            }else {
                self.scrollView.maximumZoomScale = self.maximumZoomScale * scale * self.scrollView.minimumZoomScale
                self.scrollView.minimumZoomScale = scale * self.scrollView.minimumZoomScale
                self.scrollView.zoomScale = newZoom
            }
        }
        self.reloadContentInset()
        self.isReloadindZoom = false
    }

}


extension STZoomView: UIScrollViewDelegate {
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.contentView
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        self.reloadContentInset()
        self.isSetupScrollZoomView = true
        if !self.isReloadindZoom {
            self.delegate?.zoomViewDidZoom(self)
        }
    }
    
}
