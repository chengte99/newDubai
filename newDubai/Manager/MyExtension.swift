//
//  MyExtension.swift
//  SportMap
//
//  Created by samvermette on 2019/1/28.
//  Copyright © 2019 Messaki. All rights reserved.
//

import UIKit

#if RELEASE
    func debugPrint(items: Any ..., separator: String = " ", terminator: String = "\n") { }
    func print(items: Any ..., separator: String = " ", terminator: String = "\n") { }
#endif

extension UIDevice {
    
    static var hasNotch: Bool {
        if #available(iOS 11.0, *) {
            let bottom = UIApplication.shared.keyWindow?.safeAreaInsets.bottom ?? 0
            return bottom > 0
        }
        else {
            return false
        }
    }
    
    static var safeAreaInsetsTop: CGFloat {
        if #available(iOS 11.0, *) {
            return UIApplication.shared.keyWindow?.safeAreaInsets.top ?? 0
        }
        else {
            return 0
        }
    }
    
    static var safeAreaInsetsBottom: CGFloat {
        if #available(iOS 11.0, *) {
            return UIApplication.shared.keyWindow?.safeAreaInsets.bottom ?? 0
        }
        else {
            return 0
        }
    }
}
