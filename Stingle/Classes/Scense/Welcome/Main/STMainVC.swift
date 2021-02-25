//
//  STMainVC.swift
//  Stingle
//
//  Created by Khoren Asatryan on 2/21/21.
//  Copyright © 2021 Stingle. All rights reserved.
//

import UIKit

class STMainVC: UIViewController {
	
	private let viewModel = STMainVM()
	
    override func viewDidLoad() {
        super.viewDidLoad()
		self.configure()
		self.viewModel.setupApp { [weak self] (_) in
			DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
				self?.openAppController()
			}
		}
    }
	
	//MARK: - Private func
	
	private func configure() {
		let window = UIApplication.shared.windows.first
		let statusBar = UIView(frame: window?.windowScene?.statusBarManager?.statusBarFrame ?? CGRect.zero)
		statusBar.backgroundColor = Theme.Colors.SPDarkRed
		window?.addSubview(statusBar)
		statusBar.autoresizingMask = [.flexibleHeight, .flexibleWidth]
		statusBar.layer.zPosition = 1200
	}
	
	private func openAppController() {
		let identifier = self.viewModel.isLogined() ? "goToApp" : "goToAuth"
		self.performSegue(withIdentifier: identifier, sender: nil)
	}
    

}
