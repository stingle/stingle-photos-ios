//
//  UIImageView+Operation.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/19/21.
//

import UIKit
import Kingfisher

extension UIImageView {
        
    
    func setImage(source: IRetrySource?, placeholder: UIImage? = nil) {
        if let source = source {
            
            STApplication.shared.fileRetryer.retryImage(source: source) { (image) in
                
                print("")
                
            } progress: { (progress) in
                
                print("")
                
            } failure: { (error) in
                
                print("")
                
            }

            
            
        } else {
            self.image = nil
        }
    }
        
}
