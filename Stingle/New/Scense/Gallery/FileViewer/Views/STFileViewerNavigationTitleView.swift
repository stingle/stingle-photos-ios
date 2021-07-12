//
//  STFileViewerNavigationTitleView.swift
//  Stingle
//
//  Created by Khoren Asatryan on 6/29/21.
//

import UIKit

class STFileViewerNavigationTitleView: UIView {

    @IBOutlet weak private  var titleLabel: UILabel!
    @IBOutlet weak private var subTitleLAbel: UILabel!
    
    var title: String? {
        set {
            self.titleLabel.text = newValue
        } get {
            return self.titleLabel.text
        }
    }
    
    var subTitle: String? {
        set {
            self.subTitleLAbel.text = newValue
        } get {
            return self.subTitleLAbel.text
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.setup()
    }
    
    //MARK: - Private methods
    
    private func setup() {
        self.loadNib()
    }
    
    private func loadNib() {
        let contentView = Bundle.main.loadNibNamed("STFileViewerNavigationTitleView", owner: self, options: nil)?.first as! UIView
        self.addSubviewFullContent(view: contentView)
    }

}
