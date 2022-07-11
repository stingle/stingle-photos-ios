//
//  STAppearanceVM.swift
//  Stingle
//
//  Created by Khoren Asatryan on 8/4/21.
//

import UIKit
import StingleRoot

class STAppearanceVM {
    
    lazy var appearance: STAppSettings.Appearance = {
        return STAppSettings.current.appearance
    }()
    
    func updateTheme(theme: STAppSettings.Appearance.Theme) {
        self.appearance.theme = theme
        STAppSettings.current.appearance = self.appearance
        
        UIApplication.shared.windows.forEach { window in
            window.overrideUserInterfaceStyle = theme.interfaceStyle
        }
    }
    
}
