//
//  appData.swift
//  newDubai
//
//  Created by KevinLin on 2019/6/28.
//  Copyright © 2019 KevinLin. All rights reserved.
//

import UIKit

struct AppData {
    
    // MARK: - 例外處理判斷
    
    /// 客製歡迎頁讀取文字位置
    static let customWelcomeYOffsetBF1_1: CGFloat = 12
    static let customWelcomeYOffsetBF1_2: CGFloat = 0
    static let customWelcomeYOffsetBF2_1: CGFloat = 0
    static let customWelcomeYOffsetBF2_2: CGFloat = 0
    
    /// 歡迎頁是不是白色/淺色背景
    static var isWhiteBackground: Bool {
        var result = false
        
        if let bundleID = Bundle.main.bundleIdentifier, bundleID.contains("BF178") {
            result = true
        }
        
        return result
    }
    
    /// 是不是BF178
    static var isBF: Bool {
        var result = false
        
        if let bundleID = Bundle.main.bundleIdentifier, bundleID.contains("BF178") {
            result = true
        }
        
        return result
    }
}
